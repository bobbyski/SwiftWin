import SwiftWinUI

/// Declarative demo content that exercises early `@State` and `Binding`.
struct DemoContent: View {
    @State private var projectName = "SwiftWin"
    @State private var includeDiagnostics = true
    @State private var themeIndex = 0
    @State private var scale = 50

    private var themeName: String {
        ["System", "Light", "Dark"][themeIndex]
    }

    /// Rebuildable view body using local declarations like SwiftUI.
    @ViewBuilder
    var body: some View {
        let themes = ["System", "Light", "Dark"]

        VStack(spacing: 14) {
            Text("SwiftWinUI", style: .title)
            Text("A Swift-first framework for Windows desktop apps that can finally open real windows.")
                .font(.body)
            TextField("Project name", text: $projectName)
                .frame(width: 340)
            Toggle("Include diagnostics", isOn: $includeDiagnostics)
            Picker("Theme", options: themes, selectedIndex: $themeIndex)
            Slider("Scale", value: $scale, range: 0...100)
                .frame(width: 340)
            Text("Live scale preview: \(scale)", style: .caption)
            HStack(spacing: 10) {
                Button("Create Window", style: .primary) {
                    // Use a native dialog rather than `print` so the action
                    // is visible when launched as a GUI app.
                    Dialog.show(
                        title: "Create Window",
                        message: formSummary(themeName: themes[themeIndex])
                    )
                }
                Button("Settings") {
                    Dialog.show(
                        title: "Settings",
                        message: "State and binding are now active. Next stop: automatic invalidation and view diffing."
                    )
                }
                Button("Disabled") {}
                    .disabled()
            }
            Spacer()
            Text("Native Win32 backend: active. Console renderer: still available for diagnostics.", style: .caption)
        }
        .padding(4)
    }

    /// Builds the current form summary for button actions.
    private func formSummary(themeName: String) -> String {
        """
        Project name: \(projectName)
        Diagnostics: \(includeDiagnostics ? "on" : "off")
        Theme: \(themeName)
        Scale: \(scale)
        """
    }
}

/// Declarative demo app for the SwiftUI-compatible layer.
///
/// The Windows renderer adapts this view tree into `SwiftWinLegacy` imperative
/// objects, so it should remain visually and behaviorally close to
/// `SwiftWinLegacyDemo`.
struct DemoApp: App {
    var body: some Scene {
        WindowGroup("SwiftWinUI Demo") {
            DemoContent()
        }
    }
}

DemoApp.main()
