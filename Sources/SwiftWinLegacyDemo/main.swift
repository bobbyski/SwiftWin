import SwiftWinLegacy

// This demo intentionally mirrors the SwiftWinUI declarative demo using the
// traditional imperative API. It proves that Phase II can reproduce the current
// UI directly, and that Phase I can wrap these same primitives.
let window = WinWindow(title: "SwiftWinLegacy Demo", width: 960, height: 640)
let root = WinStack(axis: .vertical, spacing: 14)
let panel = WinBackground(color: WinForegroundStyle(red: 239, green: 246, blue: 255))
let paddedRoot = WinPadding(amount: 12)

root.add(WinText("SwiftWinLegacy", style: .title, foregroundStyle: .accent))
root.add(WinText("A traditional Swift interface wrapping native Windows UI.", foregroundStyle: .secondary))

let projectName = WinTextField("Project name", text: "SwiftWin")
let projectFrame = WinFrame(width: 340, height: nil)
projectFrame.add(projectName)
root.add(projectFrame)

let includeDiagnostics = WinToggle("Include diagnostics", isOn: true)
root.add(includeDiagnostics)

let theme = WinPicker("Theme", options: ["System", "Light", "Dark"], selectedIndex: 0)
root.add(theme)

let scale = WinSlider("Scale", value: 50, range: 0...100)
let scaleFrame = WinFrame(width: 340, height: nil)
scaleFrame.add(scale)
root.add(scaleFrame)

let buttons = WinStack(axis: .horizontal, spacing: 10)
buttons.add(WinButton("Create Window", style: .primary) {
    // Visible native feedback is important for GUI-launched processes, where
    // `print` output is easy to miss.
    WinDialog.show(
        title: "Create Window",
        message: """
        Project name: \(projectName.value)
        Diagnostics: \(includeDiagnostics.isOn ? "on" : "off")
        Theme: \(["System", "Light", "Dark"][theme.selectedIndex])
        Scale: \(scale.value)
        """
    )
})
buttons.add(WinButton("Settings") {
    // This message documents the intended layering: SwiftWinUI should wrap this
    // imperative layer as the runtime grows.
    WinDialog.show(
        title: "Settings",
        message: "SwiftWinUI can wrap this imperative layer as it grows."
    )
})
let disabledButton = WinDisabled(isDisabled: true)
disabledButton.add(WinButton("Disabled") {})
buttons.add(disabledButton)

root.add(buttons)
root.add(WinSpacer())
root.add(WinText("Phase II traditional API: active.", style: .caption, foregroundStyle: .secondary))

paddedRoot.add(root)
panel.add(paddedRoot)
window.content = panel
WinApplication().run(window)
