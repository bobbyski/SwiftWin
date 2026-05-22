import SwiftWinLegacy

// This demo intentionally mirrors the SwiftWinUI declarative demo using the
// traditional imperative API. It proves that Phase II can reproduce the current
// UI directly, and that Phase I can wrap these same primitives.
let window = WinWindow(title: "SwiftWinLegacy Demo", width: 960, height: 640)
let root = WinStack(axis: .vertical, spacing: 14)

root.add(WinText("SwiftWinLegacy", style: .title))
root.add(WinText("A traditional Swift interface wrapping native Windows UI."))

let buttons = WinStack(axis: .horizontal, spacing: 10)
buttons.add(WinButton("Create Window", style: .primary) {
    // Visible native feedback is important for GUI-launched processes, where
    // `print` output is easy to miss.
    WinDialog.show(
        title: "Create Window",
        message: "This action came from the traditional SwiftWinLegacy API."
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

root.add(buttons)
root.add(WinSpacer())
root.add(WinText("Phase II traditional API: active.", style: .caption))

window.content = root
WinApplication().run(window)
