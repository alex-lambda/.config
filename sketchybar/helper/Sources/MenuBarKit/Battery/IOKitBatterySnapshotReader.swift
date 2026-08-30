import Foundation
import IOKit.ps

public struct IOKitBatterySnapshotReader: BatterySnapshotReading {
    public init() {}

    public func readSnapshot() -> BatterySnapshot? {
        guard let rawInformation = IOPSCopyPowerSourcesInfo() else { return nil }
        let information = rawInformation.takeRetainedValue()
        guard let rawSources = IOPSCopyPowerSourcesList(information) else { return nil }
        let sources = rawSources.takeRetainedValue() as [CFTypeRef]

        for source in sources {
            guard let rawDescription = IOPSGetPowerSourceDescription(information, source)?.takeUnretainedValue(),
                  let description = rawDescription as? [String: Any],
                  (description[kIOPSTypeKey] as? String) == kIOPSInternalBatteryType else {
                continue
            }

            let current = integer(description[kIOPSCurrentCapacityKey]) ?? 0
            let maximum = integer(description[kIOPSMaxCapacityKey]) ?? 100
            let percentage = maximum > 0 ? Int((Double(current) / Double(maximum) * 100).rounded()) : current
            let charging = (description[kIOPSIsChargingKey] as? Bool) ?? false
            let state = description[kIOPSPowerSourceStateKey] as? String
            let powerSource = state == kIOPSACPowerValue ? "Power Adapter" : "Battery"
            let timeKey = charging ? kIOPSTimeToFullChargeKey : kIOPSTimeToEmptyKey
            let minutes = positiveInteger(description[timeKey]) ?? systemTimeRemaining(charging: charging)
            let condition = conditionDescription(description)

            return BatterySnapshot(
                percentage: percentage,
                powerSource: powerSource,
                isCharging: charging,
                timeRemainingMinutes: minutes,
                condition: condition
            )
        }
        return nil
    }

    private func integer(_ value: Any?) -> Int? {
        guard !(value is Bool) else { return nil }
        return (value as? NSNumber)?.intValue
    }

    private func positiveInteger(_ value: Any?) -> Int? {
        guard let value = integer(value), value > 0 else { return nil }
        return value
    }

    private func systemTimeRemaining(charging: Bool) -> Int? {
        guard !charging else { return nil }
        let seconds = IOPSGetTimeRemainingEstimate()
        guard seconds > 0, seconds.isFinite else { return nil }
        return Int((seconds / 60).rounded())
    }

    private func conditionDescription(_ description: [String: Any]) -> String {
        if let condition = description[kIOPSBatteryHealthConditionKey] as? String, !condition.isEmpty {
            return condition
        }
        if let health = description[kIOPSBatteryHealthKey] as? String, !health.isEmpty {
            return health
        }
        return "Normal"
    }
}
