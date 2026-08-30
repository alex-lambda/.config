import Foundation

@main
@MainActor
struct BatteryMenuClickHandlerTests {
    static func main() {
        clickInsideBatteryWidgetDismissesOpenMenu()
        clickOutsideBatteryWidgetLeavesMenuOpen()
        print("BatteryMenuClickHandlerTests: passed")
    }

    private static let geometry = WidgetGeometry(
        frame: Rect(x: 100, y: 10, width: 40, height: 24),
        displayID: "1"
    )

    private static func clickInsideBatteryWidgetDismissesOpenMenu() {
        var dismissalCount = 0
        let handler = BatteryMenuClickHandler(geometry: geometry) {
            dismissalCount += 1
        }

        let handled = handler.handle(
            appKitClick: Point(x: 120, y: 978),
            primaryScreenTop: 1_000
        )

        precondition(handled, "the widget click must be consumed instead of reopening the menu")
        precondition(dismissalCount == 1, "clicking the battery widget must dismiss its open menu")
    }

    private static func clickOutsideBatteryWidgetLeavesMenuOpen() {
        var dismissalCount = 0
        let handler = BatteryMenuClickHandler(geometry: geometry) {
            dismissalCount += 1
        }

        let handled = handler.handle(
            appKitClick: Point(x: 80, y: 978),
            primaryScreenTop: 1_000
        )

        precondition(!handled, "clicks outside the widget must continue through normal menu handling")
        precondition(dismissalCount == 0, "clicking outside the battery widget must not trigger dismissal")
    }
}
