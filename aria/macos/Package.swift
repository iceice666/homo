// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Aria",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "Aria",
            path: "Sources/Aria"
        )
    ]
)
