// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SwiftWinUI",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "SwiftWinUI",
            targets: ["SwiftWinUI"]
        ),
        .executable(
            name: "SwiftWinUIDemo",
            targets: ["SwiftWinUIDemo"]
        )
    ],
    targets: [
        .target(
            name: "SwiftWinUI"
        ),
        .executableTarget(
            name: "SwiftWinUIDemo",
            dependencies: ["SwiftWinUI"]
        ),
        .testTarget(
            name: "SwiftWinUITests",
            dependencies: ["SwiftWinUI"]
        )
    ]
)
