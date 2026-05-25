import SwiftWinLegacy

// This demo intentionally mirrors the SwiftWinUI declarative demo using the
// traditional imperative API. It proves that Phase II can reproduce the current
// UI directly, and that Phase I can wrap these same primitives.
let window = WinWindow(title: "SwiftWinLegacy Demo", width: 960, height: 640)
let root = WinStack(axis: .vertical, spacing: 14)
let panel = WinBackground(color: WinForegroundStyle(red: 239, green: 246, blue: 255), cornerRadius: 10)
let borderedPanel = WinBorder(color: WinForegroundStyle(red: 191, green: 219, blue: 254), width: 1, cornerRadius: 10)
let paddedRoot = WinPadding(amount: 12)

let header = WinStack(axis: .vertical, spacing: 6)
header.add(WinText("SwiftWinLegacy", style: .title, foregroundStyle: .accent))
header.add(WinText("A traditional Swift interface wrapping native Windows UI.", foregroundStyle: .secondary))
root.add(header)
root.add(WinSeparator(axis: .horizontal))

let projectName = WinTextField("Project name", text: "SwiftWin")
let notes = WinTextEditor("Notes", text: "Milestone 2 notes:\nText editing is now multi-line.")
let accessCode = WinSecureField("Access code", text: "swift")
let content = WinStack(axis: .vertical, spacing: 14)

let projectFrame = WinFrame(width: 380, height: nil)
let accessibleProjectName = WinAccessibility(
    WinAccessibilityMetadata(label: "Project name", role: .textField, value: projectName.value)
)
accessibleProjectName.add(projectName)
projectFrame.add(accessibleProjectName)
content.add(projectFrame)
content.add(
    WinDynamicText(
        { projectNameValidationMessage(projectName.value) },
        style: .caption,
        foregroundStyle: .destructive
    )
)
let notesFrame = WinFrame(width: 380, height: 96)
notesFrame.add(notes)
content.add(notesFrame)
content.add(WinDynamicText({ "Notes: \(notes.value.count) characters" }, style: .caption))
let accessCodeFrame = WinFrame(width: 380, height: nil)
accessCodeFrame.add(accessCode)
content.add(accessCodeFrame)
content.add(WinDynamicText({ "Access code: \(accessCode.value.isEmpty ? "missing" : "set")" }, style: .caption))

let includeDiagnostics = WinToggle("Include diagnostics", isOn: true)
content.add(includeDiagnostics)

let theme = WinPicker("Theme", options: ["System", "Light", "Dark"], selectedIndex: 0)
content.add(theme)

let accentColor = WinColorPicker("Accent color", color: .accent)
content.add(accentColor)
content.add(
    WinDynamicText(
        { "Accent color: \(colorDescription(accentColor.color))" },
        style: .caption,
        foregroundStyle: .accent
    )
)

let launchDate = WinDatePicker("Launch date", date: WinDate(year: 2026, month: 5, day: 23))
content.add(launchDate)
content.add(WinDynamicText({ "Launch date: \(dateDescription(launchDate.date))" }, style: .caption))

let scale = WinSlider("Scale", value: 50, range: 0...100)
let scaleFrame = WinFrame(width: 380, height: nil)
scaleFrame.add(scale)
content.add(scaleFrame)
let scaleProgress = WinProgressView("Scale progress", value: { Double(scale.value) }, total: 100)
let scaleProgressFrame = WinFrame(width: 380, height: nil)
scaleProgressFrame.add(scaleProgress)
content.add(scaleProgressFrame)
let quantity = WinStepper("Quantity", value: 2, range: 0...10, variant: .integratedValue)
var hoverTarget = "None"
content.add(quantity)
content.add(WinDynamicText({ "Quantity preview: \(quantity.value)" }, style: .caption))
content.add(WinDynamicText({ "Theme preview: \(["System", "Light", "Dark"][theme.selectedIndex])" }, style: .caption))
content.add(WinDynamicText({ "Diagnostics: \(includeDiagnostics.isOn ? "enabled" : "disabled")" }, style: .caption))
content.add(WinDynamicText({ "Project summary: \(projectName.value)" }, style: .caption))
content.add(WinDynamicText({ "Hover target: \(hoverTarget)" }, style: .caption))
content.add(WinText("Renderer path: SwiftWinLegacy -> Win32", style: .caption))
content.add(WinLink("Open Swift.org", destination: "https://www.swift.org"))
content.add(WinSpacer())

root.add(content)
root.add(WinSeparator(axis: .horizontal))

let footer = WinStack(axis: .horizontal, spacing: 10)
let createWindowAccessibility = WinAccessibility(
    WinAccessibilityMetadata(label: "Create Window", role: .button, hint: "Shows the current form summary.")
)
createWindowAccessibility.add(WinButton("Create Window", style: .primary) {
    // Visible native feedback is important for GUI-launched processes, where
    // `print` output is easy to miss.
    WinDialog.show(
        title: "Create Window",
        message: """
        Project name: \(projectName.value)
        Diagnostics: \(includeDiagnostics.isOn ? "on" : "off")
        Theme: \(["System", "Light", "Dark"][theme.selectedIndex])
        Scale: \(scale.value)
        Quantity: \(quantity.value)
        Accent color: \(colorDescription(accentColor.color))
        Launch date: \(dateDescription(launchDate.date))
        Notes: \(notes.value)
        Access code: \(accessCode.value.isEmpty ? "missing" : "set")
        """
    )
})
footer.add(createWindowAccessibility)
let settingsHover = WinHover { isHovered in
    hoverTarget = isHovered ? "Settings" : "None"
    WinDynamicTextInvalidation.invalidateAll()
}
settingsHover.add(WinButton("Settings") {
    // This message documents the intended layering: SwiftWinUI should wrap this
    // imperative layer as the runtime grows.
    WinDialog.show(
        title: "Settings",
        message: "SwiftWinUI can wrap this imperative layer as it grows."
    )
})
footer.add(settingsHover)
footer.add(WinButton("Reset") {
    resetForm(
        projectName: projectName,
        includeDiagnostics: includeDiagnostics,
        theme: theme,
        scale: scale,
        quantity: quantity,
        notes: notes,
        accessCode: accessCode,
        accentColor: accentColor,
        launchDate: launchDate
    )
})
footer.add(WinButton("Cancel", role: .cancel) {
    WinDialog.show(
        title: "Cancel",
        message: "Escape routed to the explicit cancel command."
    )
})
let disabledButton = WinDisabled(isDisabled: true)
disabledButton.add(WinButton("Disabled") {})
footer.add(disabledButton)

root.add(footer)
root.add(WinText("Phase II traditional API: active.", style: .caption, foregroundStyle: .secondary))

paddedRoot.add(root)
panel.add(paddedRoot)
borderedPanel.add(panel)
window.content = borderedPanel
WinApplication().run(window)

/// Validates the project name for the imperative demo.
///
/// Implementation note:
/// This mirrors the declarative demo's inline validation behavior while using
/// the traditional API directly. Dynamic text invalidation is owned by the SDK,
/// so the app only describes the rule.
private func projectNameValidationMessage(_ value: String) -> String {
    let meaningfulCharacters = projectNameMeaningfulCharacterCount(value)
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

/// Describes a color for previews and dialogs.
private func colorDescription(_ color: WinForegroundStyle) -> String {
    "rgb(\(color.red), \(color.green), \(color.blue))"
}

/// Describes a date for previews and dialogs.
private func dateDescription(_ date: WinDate) -> String {
    "\(date.year)-\(date.month)-\(date.day)"
}

/// Resets mutable controls from imperative code.
///
/// Implementation note:
/// Traditional code owns the control objects directly. Mutating each control
/// followed by a batched refresh mirrors those values into native HWND peers
/// and then updates dependent dynamic text/progress views once.
private func resetForm(
    projectName: WinTextField,
    includeDiagnostics: WinToggle,
    theme: WinPicker,
    scale: WinSlider,
    quantity: WinStepper,
    notes: WinTextEditor,
    accessCode: WinSecureField,
    accentColor: WinColorPicker,
    launchDate: WinDatePicker
) {
    projectName.value = "SwiftWin"
    includeDiagnostics.isOn = true
    theme.selectedIndex = 0
    scale.value = 50
    quantity.value = 2
    notes.value = "Milestone 2 notes:\nText editing is now multi-line."
    accessCode.value = "swift"
    accentColor.color = .accent
    launchDate.date = WinDate(year: 2026, month: 5, day: 23)

    WinControlInvalidation.refresh([
        projectName,
        notes,
        accessCode,
        includeDiagnostics,
        theme,
        accentColor,
        launchDate,
        scale,
        quantity,
    ])
}
