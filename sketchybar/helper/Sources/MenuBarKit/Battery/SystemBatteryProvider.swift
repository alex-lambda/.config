import Foundation

public final class SystemBatteryProvider: BatteryProviding {
    public init() {
        SketchyBarMenuStateUpdater().setMenuActive(false, forItem: "battery")
    }

    public func showBatteryMenu(for request: HelperRequest) -> HelperResponse {
        guard Thread.isMainThread else {
            return .failure(requestID: request.requestID, .internalError, "Battery menu must be shown on the main thread")
        }
        guard let item = request.item, let geometry = request.widget else {
            return .failure(requestID: request.requestID, .missingItemGeometry, "Battery item geometry is unavailable")
        }

        MainActor.assumeIsolated {
            withExtendedLifetime(BatteryMenuController()) { controller in
                controller.present(for: item, geometry: geometry)
            }
        }
        return .success(requestID: request.requestID)
    }
}
