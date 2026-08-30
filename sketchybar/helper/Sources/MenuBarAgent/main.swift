import AppKit
import MenuBarKit

let application = NSApplication.shared
application.setActivationPolicy(.accessory)

let batteryProvider = SystemBatteryProvider()
let dispatcher = MenuCommandDispatcher(batteryProvider: batteryProvider)

do {
    let server = UnixSocketServer(path: try HelperSocket.defaultPath()) { request in
        if Thread.isMainThread { return dispatcher.dispatch(request) }
        return DispatchQueue.main.sync { dispatcher.dispatch(request) }
    }
    try server.start()
    withExtendedLifetime(server) {
        application.run()
    }
} catch {
    FileHandle.standardError.write(Data("MenuBarAgent failed: \(error)\n".utf8))
    exit(EXIT_FAILURE)
}
