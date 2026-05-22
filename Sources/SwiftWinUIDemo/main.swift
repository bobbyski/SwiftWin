import SwiftWinUI

/// Declarative demo app for the SwiftUI-compatible layer.
///
/// The Windows renderer adapts this view tree into `SwiftWinLegacy` imperative
/// objects, so it should remain visually and behaviorally close to
/// `SwiftWinLegacyDemo`.
struct DemoApp: App {
    var body: some Scene {
        WindowGroup("SwiftWinUI Demo") {
            VStack(spacing: 14) {
                Text("SwiftWinUI", style: .title)
                Text("A Swift-first framework for Windows desktop apps that can finally open real windows.")
                HStack(spacing: 10) {
                    Button("Create Window", style: .primary) {
                        // Use a native dialog rather than `print` so the action
                        // is visible when launched as a GUI app.
                        Dialog.show(
                            title: "Create Window",
                            message: "Button actions are wired through Win32 command routing."
                        )
                    }
                    Button("Settings") {
                        // This is intentionally aspirational: settings controls
                        // and state are the next pieces of the framework.
                        Dialog.show(
                            title: "Settings",
                            message: "Next stop: real settings controls, state, and a layout engine with taste."
                        )
                    }
                }
                Spacer()
                Text("Native Win32 backend: active. Console renderer: still available for diagnostics.", style: .caption)
            }
        }
    }
}

DemoApp.main()
