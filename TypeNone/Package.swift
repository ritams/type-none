// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TypeNone",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "TypeNone", targets: ["TypeNone"])
    ],
    dependencies: [
        // Global keyboard shortcuts
        .package(url: "https://github.com/soffes/HotKey.git", from: "0.2.0"),
        // SwiftWhisper - Swift wrapper for whisper.cpp
        .package(url: "https://github.com/exPHAT/SwiftWhisper.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "TypeNone",
            dependencies: [
                "HotKey",
                "SwiftWhisper",
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "TypeNoneTests",
            dependencies: ["TypeNone"],
            path: "Tests"
        )
    ]
)

