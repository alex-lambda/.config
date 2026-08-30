import Foundation

public protocol BatteryProviding {
    func showBatteryMenu(for request: HelperRequest) -> HelperResponse
}

public protocol MenuPresenting {
    func presentMenu(_ menu: AnyObject, anchoredTo geometry: WidgetGeometry) throws
}

public protocol SketchyBarStateUpdating {
    func setMenuActive(_ active: Bool, forItem item: String)
}

public enum LogLevel: String, Sendable { case debug, info, warning, error }

public protocol Logging {
    func log(_ level: LogLevel, _ message: String)
}

public protocol WidgetFrameLookingUp {
    func geometry(forItem item: String) throws -> WidgetGeometry
}

public struct NotImplementedBatteryProvider: BatteryProviding {
    public init() {}

    public func showBatteryMenu(for request: HelperRequest) -> HelperResponse {
        .failure(requestID: request.requestID, .notImplemented, "Battery menu support is not implemented")
    }
}

public struct MenuCommandDispatcher {
    private let batteryProvider: any BatteryProviding

    public init(batteryProvider: any BatteryProviding) {
        self.batteryProvider = batteryProvider
    }

    public func dispatch(_ request: HelperRequest) -> HelperResponse {
        guard request.version == HelperRequest.currentVersion else {
            return .failure(requestID: request.requestID, .unsupportedVersion, "Unsupported protocol version: \(request.version)")
        }

        if request.command.requiresWidget {
            guard let item = request.item, !item.isEmpty, request.widget != nil else {
                return .failure(requestID: request.requestID, .missingItemGeometry, "Menu commands require an item and widget geometry")
            }
        }

        switch request.command {
        case .ping:
            return .success(requestID: request.requestID, "pong")
        case .showBatteryMenu:
            return batteryProvider.showBatteryMenu(for: request)
        }
    }
}
