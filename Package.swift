// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Clippo",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "clippo",
            targets: ["Clippo"]
        ),
        .library(
            name: "ClippoCore",
            targets: ["ClippoCore"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ClippoCore",
            dependencies: [],
            path: "Sources/ClippoCore"
        ),
        .executableTarget(
            name: "Clippo",
            dependencies: ["ClippoCore"],
            path: "Sources/Clippo"
        ),
        .testTarget(
            name: "ClippoTests",
            dependencies: ["ClippoCore"],
            path: "Tests/ClippoTests"
        )
    ]
)
