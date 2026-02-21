// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "spotcast",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "SpotcastPluginKit", targets: ["SpotcastPluginKit"]),
        .library(name: "Plugins", targets: ["Plugins"]),
        .executable(name: "spotcast", targets: ["Spotcast"])
    ],
    targets: [
        .target(
            name: "SpotcastPluginKit",
            path: "Sources/SpotcastPluginKit"
        ),
        .target(
            name: "Plugins",
            dependencies: ["SpotcastPluginKit"],
            path: "Sources/Plugins"
        ),
        .executableTarget(
            name: "Spotcast",
            dependencies: ["SpotcastPluginKit", "Plugins"],
            path: "Sources/Spotcast"
        )
    ]
)
