// swift-tools-version: 6.0

import PackageDescription

let windowsVisualStyleManifest: [LinkerSetting] = [
    // Windows oddity:
    // Stock controls use the classic renderer unless the executable opts into
    // Common Controls v6 through an application manifest. This linker directive
    // embeds that dependency without requiring a separate .rc file yet.
    .unsafeFlags([
        "-Xlinker",
        "/manifestdependency:type='win32' name='Microsoft.Windows.Common-Controls' version='6.0.0.0' processorArchitecture='*' publicKeyToken='6595b64144ccf1df' language='*'"
    ], .when(platforms: [.windows]))
]

let package = Package(
    name: "SwiftWinUI",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "SwiftWinLegacy",
            targets: ["SwiftWinLegacy"]
        ),
        .library(
            name: "SwiftWinUI",
            targets: ["SwiftWinUI"]
        ),
        .executable(
            name: "SwiftWinLegacyDemo",
            targets: ["SwiftWinLegacyDemo"]
        ),
        .executable(
            name: "SwiftWinUIDemo",
            targets: ["SwiftWinUIDemo"]
        )
    ],
    targets: [
        .target(
            name: "SwiftWinLegacy",
            linkerSettings: [
                .linkedLibrary("gdi32", .when(platforms: [.windows])),
                .linkedLibrary("kernel32", .when(platforms: [.windows])),
                .linkedLibrary("user32", .when(platforms: [.windows])),
                .linkedLibrary("comctl32", .when(platforms: [.windows])),
                .linkedLibrary("shell32", .when(platforms: [.windows]))
            ]
        ),
        .target(
            name: "SwiftWinUI",
            dependencies: ["SwiftWinLegacy"]
        ),
        .executableTarget(
            name: "SwiftWinLegacyDemo",
            dependencies: ["SwiftWinLegacy"],
            linkerSettings: windowsVisualStyleManifest
        ),
        .executableTarget(
            name: "SwiftWinUIDemo",
            dependencies: ["SwiftWinUI"],
            linkerSettings: windowsVisualStyleManifest
        ),
        .testTarget(
            name: "SwiftWinUITests",
            dependencies: ["SwiftWinUI"]
        )
    ]
)
