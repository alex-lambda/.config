import Foundation

@MainActor
struct BatteryMenuClickHandler {
    let geometry: WidgetGeometry
    let dismiss: () -> Void

    @discardableResult
    func handle(appKitClick: Point, primaryScreenTop: Double) -> Bool {
        let sketchyBarClick = Point(
            x: appKitClick.x,
            y: primaryScreenTop - appKitClick.y
        )
        let frame = geometry.frame
        guard sketchyBarClick.x >= frame.x,
              sketchyBarClick.x <= frame.x + frame.width,
              sketchyBarClick.y >= frame.y,
              sketchyBarClick.y <= frame.y + frame.height else {
            return false
        }
        dismiss()
        return true
    }
}
