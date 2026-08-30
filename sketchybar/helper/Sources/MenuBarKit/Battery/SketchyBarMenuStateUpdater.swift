import Foundation

public struct SketchyBarMenuStateUpdater: SketchyBarStateUpdating {
    public init() {}

    public func setMenuActive(_ active: Bool, forItem item: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        let executable = ProcessInfo.processInfo.environment["SKETCHYBAR"] ?? "sketchybar"
        process.arguments = [
            executable, "--trigger", "battery_menu_state",
            "ACTIVE=\(active ? "on" : "off")",
            "ITEM=\(item)",
        ]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            // A missing or restarting SketchyBar must not prevent menu cleanup.
        }
    }
}
