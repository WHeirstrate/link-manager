// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LinkManager",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "LinkManager", path: "Sources/LinkManager")
    ]
)
