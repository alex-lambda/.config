import Foundation

public enum HelperCommand: String, Codable, CaseIterable, Sendable {
    case showBatteryMenu = "show-battery-menu"
    case ping

    public var requiresWidget: Bool { self != .ping }
}

public struct Rect: Codable, Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public var midpoint: Point { Point(x: x + width / 2, y: y + height / 2) }
}

public struct Point: Codable, Equatable, Sendable {
    public let x: Double
    public let y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public struct WidgetGeometry: Codable, Equatable, Sendable {
    public let frame: Rect
    public let displayID: String

    public init(frame: Rect, displayID: String) {
        self.frame = frame
        self.displayID = displayID
    }
}

public struct HelperRequest: Codable, Equatable, Sendable {
    public static let currentVersion = 1

    public let version: Int
    public let requestID: UUID
    public let command: HelperCommand
    public let item: String?
    public let widget: WidgetGeometry?

    public init(
        version: Int = currentVersion,
        requestID: UUID = UUID(),
        command: HelperCommand,
        item: String? = nil,
        widget: WidgetGeometry? = nil
    ) {
        self.version = version
        self.requestID = requestID
        self.command = command
        self.item = item
        self.widget = widget
    }
}

public enum ErrorCategory: String, Codable, Equatable, Sendable {
    case malformedRequest
    case unsupportedVersion
    case invalidCommand
    case missingItemGeometry
    case queryFailed
    case connectionFailed
    case permissionDenied
    case notImplemented
    case internalError
}

public struct HelperError: Codable, Error, Equatable, Sendable {
    public let category: ErrorCategory
    public let message: String

    public init(category: ErrorCategory, message: String) {
        self.category = category
        self.message = message
    }
}

public struct RequestDecodingFailure: Error, Equatable, Sendable {
    public let requestID: UUID?
    public let error: HelperError

    public init(requestID: UUID?, error: HelperError) {
        self.requestID = requestID
        self.error = error
    }
}

public struct HelperResponse: Codable, Equatable, Sendable {
    public let version: Int
    public let requestID: UUID
    public let ok: Bool
    public let message: String?
    public let error: HelperError?

    public init(
        version: Int = HelperRequest.currentVersion,
        requestID: UUID,
        ok: Bool,
        message: String? = nil,
        error: HelperError? = nil
    ) {
        self.version = version
        self.requestID = requestID
        self.ok = ok
        self.message = message
        self.error = error
    }

    public static func success(requestID: UUID, _ message: String? = nil) -> Self {
        Self(requestID: requestID, ok: true, message: message)
    }

    public static func failure(requestID: UUID, _ category: ErrorCategory, _ message: String) -> Self {
        Self(requestID: requestID, ok: false, error: HelperError(category: category, message: message))
    }
}

public enum WireCodec {
    public static func encode<T: Encodable>(_ value: T) throws -> Data {
        try JSONEncoder().encode(value)
    }

    public static func decodeRequest(_ data: Data) throws -> HelperRequest {
        do {
            return try JSONDecoder().decode(HelperRequest.self, from: data)
        } catch {
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let requestID = (object?["requestID"] as? String).flatMap(UUID.init(uuidString:))
            if let command = object?["command"] as? String,
               HelperCommand(rawValue: command) == nil {
                throw RequestDecodingFailure(
                    requestID: requestID,
                    error: HelperError(category: .invalidCommand, message: "Unknown helper command: \(command)")
                )
            }
            throw RequestDecodingFailure(
                requestID: requestID,
                error: HelperError(category: .malformedRequest, message: "Request is not valid protocol JSON")
            )
        }
    }

    public static func decodeResponse(_ data: Data) throws -> HelperResponse {
        do {
            return try JSONDecoder().decode(HelperResponse.self, from: data)
        } catch {
            throw HelperError(category: .malformedRequest, message: "Response is not valid protocol JSON")
        }
    }

}
