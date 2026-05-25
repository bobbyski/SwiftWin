import SwiftWinUI

/// Declarative demo content that exercises early `@State` and `Binding`.
struct DemoContent: View {
    @State private var projectName = "SwiftWin"
    @State private var includeDiagnostics = true
    @State private var themeIndex = 0
    @State private var scale = 50
    @State private var quantity = 2
    @State private var notes = "Milestone 2 notes:\nText editing is now multi-line."
    @State private var accessCode = "swift"
    @State private var accentColor = Color.accent
    @State private var launchDate = CalendarDate(year: 2026, month: 5, day: 23)
    @State private var hoverTarget = "None"

    private var themeName: String {
        ["System", "Light", "Dark"][themeIndex]
    }

    /// Inline project-name validation used by the form demo.
    private var projectNameValidationMessage: String {
        let meaningfulCharacters = projectNameMeaningfulCharacterCount(projectName)
        if meaningfulCharacters == 0 {
            return "Project name is required."
        }
        if meaningfulCharacters < 3 {
            return "Project name needs at least 3 characters."
        }
        return ""
    }

    /// Counts non-whitespace characters for lightweight validation.
    private func projectNameMeaningfulCharacterCount(_ value: String) -> Int {
        value.filter { !$0.isWhitespace }.count
    }

    /// Rebuildable view body using local declarations like SwiftUI.
    @ViewBuilder
    var body: some View {
        let themes = ["System", "Light", "Dark"]

        VStack(spacing: 14) {
            header
            Divider()
            ScrollView {
                content(themes: themes)
            }
            .frame(width: 760, height: 360)
            Divider()
            footer(themes: themes)
            Text("Native Win32 backend: active. Console renderer: still available for diagnostics.", style: .caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(red: 239, green: 246, blue: 255))
        .border(Color(red: 191, green: 219, blue: 254), width: 1)
        .cornerRadius(10)
    }

    /// Header area for the demo window.
    @ViewBuilder
    private var header: some View {
        VStack(spacing: 6) {
            Text("SwiftWinUI", style: .title)
                .foregroundStyle(.accent)
            Text("A Swift-first framework for Windows desktop apps that can finally open real windows.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    /// Center content area with enough rows to exercise wheel scrolling.
    @ViewBuilder
    private func content(themes: [String]) -> some View {
        VStack(spacing: 14) {
            TextField("Project name", text: $projectName)
                .frame(width: 380)
                .accessibilityLabel("Project name")
                .accessibilityRole(.textField)
                .accessibilityValue(projectName)
            Text(projectNameValidationMessage, style: .caption)
                .foregroundStyle(.destructive)
            TextEditor("Notes", text: $notes)
                .frame(width: 380, height: 96)
            Text("Notes: \(notes.count) characters", style: .caption)
            SecureField("Access code", text: $accessCode)
                .frame(width: 380)
            Text("Access code: \(accessCode.isEmpty ? "missing" : "set")", style: .caption)
            Toggle("Include diagnostics", isOn: $includeDiagnostics)
            Picker("Theme", options: themes, selectedIndex: $themeIndex)
            ColorPicker("Accent color", selection: $accentColor)
            Text("Accent color: \(colorDescription(accentColor))", style: .caption)
                .foregroundStyle(accentColor)
            DatePicker("Launch date", selection: $launchDate)
            Text("Launch date: \(dateDescription(launchDate))", style: .caption)
            Slider("Scale", value: $scale, range: 0...100)
                .frame(width: 380)
            Text("Live scale preview: \(scale)", style: .caption)
            ProgressView("Scale progress", value: scale, total: 100)
                .frame(width: 380)
            Stepper("Quantity", value: $quantity, range: 0...10, variant: .integratedValue)
            Text("Quantity preview: \(quantity)", style: .caption)
            Text("Theme preview: \(themes[themeIndex])", style: .caption)
            Text("Diagnostics: \(includeDiagnostics ? "enabled" : "disabled")", style: .caption)
            Text("Project summary: \(projectName)", style: .caption)
            Text("Hover target: \(hoverTarget)", style: .caption)
            Text("Renderer path: SwiftWinUI -> SwiftWinLegacy -> Win32", style: .caption)
            Link("Open Swift.org", destination: "https://www.swift.org")
            Spacer()
        }
    }

    /// Footer area for command buttons.
    @ViewBuilder
    private func footer(themes: [String]) -> some View {
        HStack(spacing: 10) {
            Button("Create Window", style: .primary) {
                // Use a native dialog rather than `print` so the action
                // is visible when launched as a GUI app.
                Dialog.show(
                    title: "Create Window",
                    message: formSummary(themeName: themes[themeIndex])
                )
            }
            .accessibilityLabel("Create Window")
            .accessibilityRole(.button)
            .accessibilityHint("Shows the current form summary.")
            Button("Settings") {
                Dialog.show(
                    title: "Settings",
                    message: "State and binding are now active. Next stop: automatic invalidation and view diffing."
                )
            }
            .onHover { isHovered in
                hoverTarget = isHovered ? "Settings" : "None"
            }
            Button("Reset") {
                resetForm()
            }
            Button("Cancel", role: .cancel) {
                Dialog.show(
                    title: "Cancel",
                    message: "Escape routed to the explicit cancel command."
                )
            }
            Button("Disabled") {}
                .disabled()
        }
    }

    /// Resets bound controls from code to exercise native invalidation.
    private func resetForm() {
        projectName = "SwiftWin"
        includeDiagnostics = true
        themeIndex = 0
        scale = 50
        quantity = 2
        notes = "Milestone 2 notes:\nText editing is now multi-line."
        accessCode = "swift"
        accentColor = .accent
        launchDate = CalendarDate(year: 2026, month: 5, day: 23)
        hoverTarget = "None"
    }

    /// Builds the current form summary for button actions.
    private func formSummary(themeName: String) -> String {
        """
        Project name: \(projectName)
        Diagnostics: \(includeDiagnostics ? "on" : "off")
        Theme: \(themeName)
        Scale: \(scale)
        Quantity: \(quantity)
        Accent color: \(colorDescription(accentColor))
        Launch date: \(dateDescription(launchDate))
        Notes: \(notes)
        Access code: \(accessCode.isEmpty ? "missing" : "set")
        """
    }

    /// Describes a semantic RGB color for demo previews and dialogs.
    private func colorDescription(_ color: Color) -> String {
        "rgb(\(color.red), \(color.green), \(color.blue))"
    }

    /// Describes a calendar date for demo previews and dialogs.
    private func dateDescription(_ date: CalendarDate) -> String {
        "\(date.year)-\(date.month)-\(date.day)"
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
