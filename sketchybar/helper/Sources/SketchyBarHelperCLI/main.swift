import CoreGraphics
import Foundation
import MenuBarKit

private enum CLIError: Error {
    case usage
    case sketchybarFailed(String)
    case responseMismatch
}

private func parseArguments(_ arguments: [String]) throws -> (HelperCommand, String?) {
    guard let name = arguments.first, let command = HelperCommand(rawValue: name) else { throw CLIError.usage }
    if command == .ping {
        guard arguments.count == 1 else { throw CLIError.usage }
        return (command, nil)
    }
    guard arguments.count == 3, arguments[1] == "--item", !arguments[2].isEmpty else { throw CLIError.usage }
    return (command, arguments[2])
}

private func queryGeometry(item: String) throws -> WidgetGeometry {
    let process = Process()
    let output = Pipe()
    let errors = Pipe()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["sketchybar", "--query", item]
    process.standardOutput = output
    process.standardError = errors
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        let detail = String(decoding: errors.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        throw CLIError.sketchybarFailed(detail.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    let candidates = try SketchyBarQueryParser.boundingRects(from: output.fileHandleForReading.readDataToEndOfFile())
    let pointer = CGEvent(source: nil)?.location
    return try DisplayFrameSelector.select(
        from: candidates,
        pointer: pointer.map { Point(x: $0.x, y: $0.y) }
    )
}

private func printUsage() {
    let usage = """
    Usage:
      sketchybar-helperctl ping
      sketchybar-helperctl show-battery-menu --item <name>
    """
    FileHandle.standardError.write(Data("\(usage)\n".utf8))
}

do {
    let (command, item) = try parseArguments(Array(CommandLine.arguments.dropFirst()))
    let geometry = try item.map(queryGeometry)
    let request = HelperRequest(command: command, item: item, widget: geometry)
    let response = try UnixSocketClient(path: HelperSocket.defaultPath()).send(request)
    guard response.requestID == request.requestID else { throw CLIError.responseMismatch }
    if response.ok {
        if let message = response.message { print(message) }
        exit(EXIT_SUCCESS)
    }
    FileHandle.standardError.write(Data("\(response.error?.category.rawValue ?? "internalError"): \(response.error?.message ?? "Unknown helper error")\n".utf8))
    exit(2)
} catch CLIError.usage {
    printUsage()
    exit(64)
} catch {
    FileHandle.standardError.write(Data("sketchybar-helperctl: \(error)\n".utf8))
    exit(EXIT_FAILURE)
}
