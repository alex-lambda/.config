import Foundation

public struct EnergyProcess: Equatable, Sendable {
    public let name: String
    public let impact: String

    public init(name: String, impact: String) {
        self.name = name
        self.impact = impact
    }
}

public protocol EnergyProcessReading {
    func highEnergyProcesses() -> [EnergyProcess]
}

/// macOS does not expose Activity Monitor's Energy Impact through a supported
/// public API. Keep this capability empty rather than substitute CPU usage or
/// invoke privileged/private tools; the menu accepts richer readers if a future
/// public API becomes available.
public struct SystemEnergyProcessReader: EnergyProcessReading {
    public init() {}

    public func highEnergyProcesses() -> [EnergyProcess] { [] }
}
