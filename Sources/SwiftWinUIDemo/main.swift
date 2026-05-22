import SwiftWinUI

/// Tiny reference state used until SwiftWinUI has `@State` and `Binding`.
///
/// This keeps the demo honest: `TextField` changes flow from the native edit
/// control into Swift, and the button reads the latest value.
final class DemoFormState {
    var projectName = "SwiftWin"
    var includeDiagnostics = true
    var themeIndex = 0
    var scale = 50

    var summary: String {
        """
        Project name: \(projectName)
        Diagnostics: \(includeDiagnostics ? "on" : "off")
        Theme: \(themeName)
        Scale: \(scale)
        """
    }

    private var themeName: String {
        ["System", "Light", "Dark"][themeIndex]
    }
}

/// Declarative demo app for the SwiftUI-compatible layer.
///
/// The Windows renderer adapts this view tree into `SwiftWinLegacy` imperative
/// objects, so it should remain visually and behaviorally close to
/// `SwiftWinLegacyDemo`.
struct DemoApp: App {
    var body: some Scene {
        let form = DemoFormState()

        WindowGroup("SwiftWinUI Demo") {
            VStack(spacing: 14) {
                Text("SwiftWinUI", style: .title)
                Text("A Swift-first framework for Windows desktop apps that can finally open real windows.")
                TextField("Project name", text: form.projectName) { value in
                    form.projectName = value
                }
                Toggle("Include diagnostics", isOn: form.includeDiagnostics) { value in
                    form.includeDiagnostics = value
                }
                Picker("Theme", options: ["System", "Light", "Dark"], selectedIndex: form.themeIndex) { index in
                    form.themeIndex = index
                }
                Slider("Scale", value: form.scale, range: 0...100) { value in
                    form.scale = value
                }
                HStack(spacing: 10) {
                    Button("Create Window", style: .primary) {
                        // Use a native dialog rather than `print` so the action
                        // is visible when launched as a GUI app.
                        Dialog.show(
                            title: "Create Window",
                            message: form.summary
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
