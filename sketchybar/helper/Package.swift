// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SketchyBarHelper",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "MenuBarKit", targets: ["MenuBarKit"]),
        .executable(name: "MenuBarAgent", targets: ["MenuBarAgent"]),
        .executable(name: "sketchybar-helperctl", targets: ["SketchyBarHelperCLI"]),
    ],
    targets: [
        .target(name: "MenuBarKit"),
        .executableTarget(name: "MenuBarAgent", dependencies: ["MenuBarKit"]),
        .executableTarget(name: "SketchyBarHelperCLI", dependencies: ["MenuBarKit"]),
    ]
)
