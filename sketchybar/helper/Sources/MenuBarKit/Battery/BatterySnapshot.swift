import Foundation

public struct BatterySnapshot: Equatable, Sendable {
    public let percentage: Int
    public let powerSource: String
    public let isCharging: Bool
    public let timeRemainingMinutes: Int?
    public let condition: String

    public init(
        percentage: Int,
        powerSource: String,
        isCharging: Bool,
        timeRemainingMinutes: Int?,
        condition: String
    ) {
        self.percentage = min(100, max(0, percentage))
        self.powerSource = powerSource
        self.isCharging = isCharging
        self.timeRemainingMinutes = timeRemainingMinutes
        self.condition = condition
    }

    public var timeRemainingDescription: String {
        guard let minutes = timeRemainingMinutes, minutes > 0 else { return "Calculating…" }
        let hours = minutes / 60
        let remainder = minutes % 60
        if hours == 0 { return "\(remainder)m" }
        if remainder == 0 { return "\(hours)h" }
        return "\(hours)h \(remainder)m"
    }
}

public protocol BatterySnapshotReading {
    func readSnapshot() -> BatterySnapshot?
}
