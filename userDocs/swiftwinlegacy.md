# Traditional SwiftWinLegacy API

`SwiftWinLegacy` is the traditional, non-declarative Swift library for Windows UI.

It is developed in parallel with `SwiftWinUI`. The current plan is for `SwiftWinUI` to wrap `SwiftWinLegacy` primitives where that keeps the architecture simpler and avoids duplicate native control code.

## Current Status

Implemented:

- `WinApplication`
- `WinWindow`
- `WinApplicationRunning`
- `WinContainer`
- `WinTextDisplaying`
- `WinEditableText`
- `WinTitledControl`
- `WinActionControl`
- `WinButtonDisplaying`
- `WinStack`
- `WinText`
- `WinTextField`
- `WinToggle`
- `WinPicker`
- `WinSlider`
- `WinStepper`
- `WinProgressView`
- `WinButton`
- `WinSpacer`
- `WinDialog`
- `SwiftWinLegacyDemo`

The first milestone is complete: `SwiftWinLegacyDemo` reproduces the current SwiftWinUI demo through the imperative API.

## Design Direction

`SwiftWinLegacy` should stay traditional and explicit, but it should also be protocol-oriented where that keeps the API safer and easier to extend.

Current public protocols cover app runners, containers, text elements, editable text, titled controls, action controls, and button-like controls. The concrete classes are the default implementations, not the only possible implementations.

Implementation functions should stay small. The current Win32 runtime is still intentionally compact for the prototype, but the plan is to split it into protocol contracts, controls, layout, event routing, Win32 declarations, and paint/resource management as the framework grows.

## Example

```swift
import SwiftWinLegacy

let window = WinWindow(title: "SwiftWinLegacy Demo", width: 960, height: 640)
let root = WinStack(axis: .vertical, spacing: 14)

root.add(WinText("SwiftWinLegacy", style: .title))
root.add(WinText("A traditional Swift interface wrapping native Windows UI."))
let projectName = WinTextField("Project name", text: "SwiftWin")
root.add(projectName)
let includeDiagnostics = WinToggle("Include diagnostics", isOn: true)
root.add(includeDiagnostics)
let theme = WinPicker("Theme", options: ["System", "Light", "Dark"])
root.add(theme)
let scale = WinSlider("Scale", value: 50, range: 0...100)
root.add(scale)
let quantity = WinStepper("Quantity", value: 2, range: 0...10, variant: .integratedValue)
root.add(quantity)
let progress = WinProgressView("Scale progress", value: { Double(scale.value) }, total: 100)
root.add(progress)

let buttons = WinStack(axis: .horizontal, spacing: 10)
buttons.add(WinButton("Create Window", style: .primary) {
    WinDialog.show(title: "Create Window", message: "Project name: \(projectName.value), scale: \(scale.value)")
})
buttons.add(WinButton("Settings") {
    WinDialog.show(title: "Settings", message: "Settings clicked.")
})

root.add(buttons)
root.add(WinSpacer())
root.add(WinText("Phase II traditional API: active.", style: .caption))

window.content = root
WinApplication().run(window)
```

## Run The Demo

```powershell
swift build
.\.build\aarch64-unknown-windows-msvc\debug\SwiftWinLegacyDemo.exe
```

## Relationship To SwiftWinUI

`SwiftWinUI` depends on `SwiftWinLegacy`.

The current `Win32Renderer` adapter converts declarative SwiftWinUI render calls into imperative `SwiftWinLegacy` objects:

- `Text` -> `WinText`
- `TextField` -> `WinTextField`
- `Toggle` -> `WinToggle`
- `Picker` -> `WinPicker`
- `Slider` -> `WinSlider`
- `Stepper` -> `WinStepper`
- `ProgressView` -> `WinProgressView`
- `Button` -> `WinButton`
- `VStack` / `HStack` -> `WinStack`
- `Spacer` -> `WinSpacer`
- `Dialog.show` -> `WinDialog.show`

This is the intended simultaneous development model unless a future architectural change proves cleaner.

## Refreshing Controls

Traditional apps can mutate control objects directly. For controls backed by
native HWND peers, call `refresh()` after a code-driven change to mirror the new
Swift value into the live window and update dependent dynamic text/progress:

```swift
projectName.value = "SwiftWin"
includeDiagnostics.isOn = true
theme.selectedIndex = 0
scale.value = 50
quantity.value = 2

projectName.refresh()
includeDiagnostics.refresh()
theme.refresh()
scale.refresh()
quantity.refresh()
```

Current refreshable controls are `WinTextField`, `WinToggle`, `WinPicker`,
`WinSlider`, and `WinStepper`. User-driven edits refresh dependent dynamic text
automatically through the Win32 event path.
