import AppKit

@MainActor
final class BatteryMenuController: NSObject {
    private let snapshotReader: any BatterySnapshotReading
    private let energyProcessReader: any EnergyProcessReading
    private let stateUpdater: any SketchyBarStateUpdating

    init(
        snapshotReader: any BatterySnapshotReading = IOKitBatterySnapshotReader(),
        energyProcessReader: any EnergyProcessReading = SystemEnergyProcessReader(),
        stateUpdater: any SketchyBarStateUpdating = SketchyBarMenuStateUpdater()
    ) {
        self.snapshotReader = snapshotReader
        self.energyProcessReader = energyProcessReader
        self.stateUpdater = stateUpdater
    }

    func present(for item: String, geometry: WidgetGeometry) {
        let menu = makeMenu(snapshot: snapshotReader.readSnapshot())
        let anchor = menuAnchor(for: geometry)
        let primaryScreenTop = NSScreen.screens.first?.frame.maxY ?? 0
        let clickHandler = BatteryMenuClickHandler(geometry: geometry) {
            menu.cancelTracking()
        }
        let localMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { event in
            let location = NSEvent.mouseLocation
            let handled = MainActor.assumeIsolated {
                clickHandler.handle(
                    appKitClick: Point(x: location.x, y: location.y),
                    primaryScreenTop: primaryScreenTop
                )
            }
            return handled ? nil : event
        }
        let globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { _ in
            let location = NSEvent.mouseLocation
            DispatchQueue.main.async {
                clickHandler.handle(
                    appKitClick: Point(x: location.x, y: location.y),
                    primaryScreenTop: primaryScreenTop
                )
            }
        }

        stateUpdater.setMenuActive(true, forItem: item)
        defer {
            if let localMonitor { NSEvent.removeMonitor(localMonitor) }
            if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
            stateUpdater.setMenuActive(false, forItem: item)
        }
        menu.popUp(positioning: nil, at: anchor, in: nil)
    }

    private func makeMenu(snapshot: BatterySnapshot?) -> NSMenu {
        let menu = NSMenu(title: "Battery")
        menu.autoenablesItems = false

        if let snapshot {
            addInformation("Available Charge", value: "\(snapshot.percentage)%", to: menu)
            addInformation("Power Source", value: snapshot.powerSource, to: menu)
            addInformation("Charging", value: snapshot.isCharging ? "Yes" : "No", to: menu)
            addInformation(
                snapshot.isCharging ? "Time to Full" : "Time Remaining",
                value: snapshot.timeRemainingDescription,
                to: menu
            )
            addInformation("Condition", value: snapshot.condition, to: menu)
        } else {
            addInformation("Battery", value: "Not Available", to: menu)
        }

        let energyProcesses = energyProcessReader.highEnergyProcesses().prefix(5)
        if !energyProcesses.isEmpty {
            menu.addItem(.separator())
            let heading = NSMenuItem(title: "High Energy Use", action: nil, keyEquivalent: "")
            heading.isEnabled = false
            menu.addItem(heading)
            for process in energyProcesses {
                addInformation(process.name, value: process.impact, to: menu)
            }
        }

        menu.addItem(.separator())
        menu.addItem(actionItem("Battery Settings…", action: #selector(openBatterySettings)))
        menu.addItem(actionItem("Activity Monitor…", action: #selector(openActivityMonitor)))
        return menu
    }

    private func addInformation(_ title: String, value: String, to menu: NSMenu) {
        let item = NSMenuItem(title: "\(title):  \(value)", action: nil, keyEquivalent: "")
        item.isEnabled = false
        menu.addItem(item)
    }

    private func actionItem(_ title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.isEnabled = true
        return item
    }

    private func menuAnchor(for geometry: WidgetGeometry) -> NSPoint {
        let primaryTop = NSScreen.screens.first?.frame.maxY ?? 0
        return NSPoint(
            x: geometry.frame.x,
            y: primaryTop - geometry.frame.y - geometry.frame.height
        )
    }

    @objc private func openBatterySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Battery-Settings.extension") else { return }
        NSWorkspace.shared.open(url)
    }

    @objc private func openActivityMonitor() {
        NSWorkspace.shared.openApplication(
            at: URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"),
            configuration: NSWorkspace.OpenConfiguration()
        )
    }
}
