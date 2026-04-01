// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ClaudeBar",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "ClaudeBar", targets: ["ClaudeBar"]),
    ],
    targets: [
        .target(
            name: "ClaudeBarCore",
            path: "Sources/ClaudeBarCore"
        ),
        .executableTarget(
            name: "ClaudeBar",
            dependencies: ["ClaudeBarCore"],
            path: "Sources/ClaudeBar",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "ClaudeBarCoreTests",
            dependencies: ["ClaudeBarCore"],
            path: "Tests/ClaudeBarCoreTests"
        ),
    ]
)
