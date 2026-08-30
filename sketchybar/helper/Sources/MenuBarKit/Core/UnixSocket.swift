import Darwin
import Foundation

public enum SocketError: Error, Equatable {
    case invalidRuntimeDirectory
    case unsafeExistingPath
    case pathTooLong
    case systemCall(String, Int32)
    case peerRejected
    case connectionClosed
    case oversizedFrame
    case truncatedFrame
    case agentAlreadyRunning
}

public enum HelperSocket {
    public static let bundleIdentifier = "com.alexlam.sketchybar.helper"
    public static let maximumFrameSize = 1_048_576

    public static func defaultPath(environment: [String: String] = ProcessInfo.processInfo.environment) throws -> String {
        let base = environment["TMPDIR"] ?? NSTemporaryDirectory()
        let directory = URL(fileURLWithPath: base, isDirectory: true)
            .appendingPathComponent(bundleIdentifier, isDirectory: true).path
        try preparePrivateDirectory(directory)
        return URL(fileURLWithPath: directory).appendingPathComponent("agent.sock").path
    }

    private static func preparePrivateDirectory(_ path: String) throws {
        var info = stat()
        if lstat(path, &info) == 0 {
            guard (info.st_mode & S_IFMT) == S_IFDIR,
                  info.st_uid == getuid(),
                  (info.st_mode & 0o077) == 0 else {
                throw SocketError.invalidRuntimeDirectory
            }
            return
        }
        guard errno == ENOENT else { throw SocketError.systemCall("lstat", errno) }
        guard mkdir(path, 0o700) == 0 else { throw SocketError.systemCall("mkdir", errno) }
    }
}

public enum FramedTransport {
    public static func write(_ payload: Data, to descriptor: Int32) throws {
        guard payload.count <= HelperSocket.maximumFrameSize else { throw SocketError.oversizedFrame }
        var length = UInt32(payload.count).bigEndian
        try withUnsafeBytes(of: &length) { try writeAll(Data($0), to: descriptor) }
        try writeAll(payload, to: descriptor)
    }

    public static func read(from descriptor: Int32) throws -> Data {
        let header = try readExactly(4, from: descriptor)
        let length = header.withUnsafeBytes { raw -> UInt32 in
            raw.loadUnaligned(as: UInt32.self).bigEndian
        }
        guard length <= HelperSocket.maximumFrameSize else { throw SocketError.oversizedFrame }
        return try readExactly(Int(length), from: descriptor)
    }

    private static func writeAll(_ data: Data, to descriptor: Int32) throws {
        try data.withUnsafeBytes { raw in
            guard let base = raw.baseAddress else { return }
            var offset = 0
            while offset < raw.count {
                let count = Darwin.send(descriptor, base.advanced(by: offset), raw.count - offset, Int32(MSG_NOSIGNAL))
                if count < 0 {
                    if errno == EINTR { continue }
                    throw SocketError.systemCall("write", errno)
                }
                guard count > 0 else { throw SocketError.connectionClosed }
                offset += count
            }
        }
    }

    private static func readExactly(_ byteCount: Int, from descriptor: Int32) throws -> Data {
        if byteCount == 0 { return Data() }
        var data = Data(count: byteCount)
        var offset = 0
        try data.withUnsafeMutableBytes { raw in
            guard let base = raw.baseAddress else { return }
            while offset < byteCount {
                let count = Darwin.read(descriptor, base.advanced(by: offset), byteCount - offset)
                if count < 0 {
                    if errno == EINTR { continue }
                    throw SocketError.systemCall("read", errno)
                }
                guard count > 0 else { throw SocketError.truncatedFrame }
                offset += count
            }
        }
        return data
    }
}

public final class UnixSocketClient {
    private let path: String

    public init(path: String) { self.path = path }

    public func send(_ request: HelperRequest) throws -> HelperResponse {
        let descriptor = socket(AF_UNIX, SOCK_STREAM, 0)
        guard descriptor >= 0 else { throw SocketError.systemCall("socket", errno) }
        defer { close(descriptor) }
        var address = try socketAddress(path: path)
        let addressLength = socklen_t(address.sun_len)
        let result = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(descriptor, $0, addressLength)
            }
        }
        guard result == 0 else { throw SocketError.systemCall("connect", errno) }
        try FramedTransport.write(try WireCodec.encode(request), to: descriptor)
        return try WireCodec.decodeResponse(FramedTransport.read(from: descriptor))
    }
}

public final class UnixSocketServer: @unchecked Sendable {
    private let path: String
    private let handler: (HelperRequest) -> HelperResponse
    private var descriptor: Int32 = -1
    private var ownsSocket = false

    public init(path: String, handler: @escaping (HelperRequest) -> HelperResponse) {
        self.path = path
        self.handler = handler
    }

    deinit { stop() }

    public func start() throws {
        var didStart = false
        defer {
            if !didStart { stop() }
        }

        try removeStaleSocketIfSafe()
        let oldMask = umask(0o077)
        defer { umask(oldMask) }

        descriptor = socket(AF_UNIX, SOCK_STREAM, 0)
        guard descriptor >= 0 else { throw SocketError.systemCall("socket", errno) }
        var address = try socketAddress(path: path)
        let addressLength = socklen_t(address.sun_len)
        let bindResult = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(descriptor, $0, addressLength)
            }
        }
        guard bindResult == 0 else { throw SocketError.systemCall("bind", errno) }
        ownsSocket = true
        guard chmod(path, 0o600) == 0 else {
            stop()
            throw SocketError.systemCall("chmod", errno)
        }
        guard listen(descriptor, 8) == 0 else { throw SocketError.systemCall("listen", errno) }

        DispatchQueue(label: "com.alexlam.sketchybar.helper.socket").async { [weak self] in
            self?.acceptLoop()
        }
        didStart = true
    }

    public func stop() {
        if descriptor >= 0 {
            close(descriptor)
            descriptor = -1
        }
        if ownsSocket {
            unlink(path)
            ownsSocket = false
        }
    }

    private func acceptLoop() {
        while descriptor >= 0 {
            let client = accept(descriptor, nil, nil)
            if client < 0 {
                if errno == EINTR { continue }
                return
            }
            autoreleasepool { handle(client) }
            close(client)
        }
    }

    private func handle(_ client: Int32) {
        var effectiveUID: uid_t = 0
        var effectiveGID: gid_t = 0
        guard getpeereid(client, &effectiveUID, &effectiveGID) == 0, effectiveUID == getuid() else { return }

        let response: HelperResponse
        do {
            let request = try WireCodec.decodeRequest(FramedTransport.read(from: client))
            response = handler(request)
        } catch let failure as RequestDecodingFailure {
            response = .failure(
                requestID: failure.requestID ?? UUID(),
                failure.error.category,
                failure.error.message
            )
        } catch {
            response = .failure(requestID: UUID(), .malformedRequest, "Could not decode request")
        }
        try? FramedTransport.write(try WireCodec.encode(response), to: client)
    }

    private func removeStaleSocketIfSafe() throws {
        var info = stat()
        guard lstat(path, &info) == 0 else {
            if errno == ENOENT { return }
            throw SocketError.systemCall("lstat", errno)
        }
        guard (info.st_mode & S_IFMT) == S_IFSOCK, info.st_uid == getuid() else {
            throw SocketError.unsafeExistingPath
        }
        if try socketIsAcceptingConnections() {
            throw SocketError.agentAlreadyRunning
        }
        guard unlink(path) == 0 else { throw SocketError.systemCall("unlink", errno) }
    }

    private func socketIsAcceptingConnections() throws -> Bool {
        let probe = socket(AF_UNIX, SOCK_STREAM, 0)
        guard probe >= 0 else { throw SocketError.systemCall("socket", errno) }
        defer { close(probe) }

        var address = try socketAddress(path: path)
        let addressLength = socklen_t(address.sun_len)
        let result = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(probe, $0, addressLength)
            }
        }
        if result == 0 { return true }
        if errno == ECONNREFUSED || errno == ENOENT { return false }
        throw SocketError.systemCall("connect", errno)
    }
}

private func socketAddress(path: String) throws -> sockaddr_un {
    let bytes = Array(path.utf8) + [0]
    var address = sockaddr_un()
    let capacity = MemoryLayout.size(ofValue: address.sun_path)
    guard bytes.count <= capacity else { throw SocketError.pathTooLong }
    address.sun_family = sa_family_t(AF_UNIX)
    address.sun_len = UInt8(MemoryLayout<sa_family_t>.size + bytes.count)
    withUnsafeMutablePointer(to: &address.sun_path) { pointer in
        pointer.withMemoryRebound(to: UInt8.self, capacity: capacity) { destination in
            for (index, byte) in bytes.enumerated() { destination[index] = byte }
        }
    }
    return address
}
