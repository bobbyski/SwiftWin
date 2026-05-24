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
- `WinSecureField`
- `WinTextEditor`
- `WinToggle`
- `WinPicker`
- `WinSlider`
- `WinStepper`
- `WinColorPicker`
- `WinDatePicker`
- `WinProgressView`
- `WinButton`
- `WinButtonRole`
- `WinHover`
- `WinLink`
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
let accessCode = WinSecureField("Access code", text: "")
root.add(accessCode)
let notes = WinTextEditor("Notes", text: "Milestone notes")
root.add(notes)
let includeDiagnostics = WinToggle("Include diagnostics", isOn: true)
root.add(includeDiagnostics)
let theme = WinPicker("Theme", options: ["System", "Light", "Dark"])
root.add(theme)
let scale = WinSlider("Scale", value: 50, range: 0...100)
root.add(scale)
let quantity = WinStepper("Quantity", value: 2, range: 0...10, variant: .integratedValue)
root.add(quantity)
let accentColor = WinColorPicker("Accent color", color: .accent)
root.add(accentColor)
let launchDate = WinDatePicker("Launch date", date: WinDate(year: 2026, month: 5, day: 23))
root.add(launchDate)
let progress = WinProgressView("Scale progress", value: { Double(scale.value) }, total: 100)
root.add(progress)
root.add(WinLink("Open Swift.org", destination: "https://www.swift.org"))

let buttons = WinStack(axis: .horizontal, spacing: 10)
buttons.add(WinButton("Create Window", style: .primary) {
    WinDialog.show(title: "Create Window", message: "Project name: \(projectName.value), scale: \(scale.value)")
})
buttons.add(WinButton("Cancel", role: .cancel) {
    WinDialog.show(title: "Cancel", message: "Escape routed to the cancel command.")
})
let settingsHover = WinHover { isHovered in
    print(isHovered ? "Settings hover entered" : "Settings hover exited")
}
settingsHover.add(WinButton("Settings") {
    WinDialog.show(title: "Settings", message: "Settings clicked.")
})
buttons.add(settingsHover)

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
- `SecureField` -> `WinSecureField`
- `TextEditor` -> `WinTextEditor`
- `Toggle` -> `WinToggle`
- `Picker` -> `WinPicker`
- `Slider` -> `WinSlider`
- `Stepper` -> `WinStepper`
- `ProgressView` -> `WinProgressView`
- `ColorPicker` -> `WinColorPicker`
- `DatePicker` -> `WinDatePicker`
- `Button` -> `WinButton`
- `ButtonRole` -> `WinButtonRole`
- `.onHover` -> `WinHover`
- `Link` -> `WinLink`
- `VStack` / `HStack` -> `WinStack`
- `Spacer` -> `WinSpacer`
- `Dialog.show` -> `WinDialog.show`

This is the intended simultaneous development model unless a future architectural change proves cleaner.

## Refreshing Controls

Traditional apps can mutate control objects directly. For one control backed by
a native HWND peer, call `refresh()` after a code-driven change to mirror the
new Swift value into the live window and update dependent dynamic text/progress:

```swift
projectName.value = "SwiftWin"
includeDiagnostics.isOn = true
theme.selectedIndex = 0
scale.value = 50
quantity.value = 2
accentColor.color = .accent
launchDate.date = WinDate(year: 2026, month: 5, day: 23)

scale.refresh()
```

When changing several controls together, prefer a batched refresh so dependent
dynamic text and progress views update once:

```swift
WinControlInvalidation.refresh([
    projectName,
    accessCode,
    notes,
    includeDiagnostics,
    theme,
    scale,
    quantity,
    accentColor,
    launchDate,
])
```

Current refreshable controls are `WinTextField`, `WinSecureField`,
`WinTextEditor`, `WinToggle`, `WinPicker`, `WinSlider`, `WinStepper`, and
`WinColorPicker`, and `WinDatePicker`.
User-driven edits refresh dependent dynamic text automatically through the
Win32 event path.

## Observing Hover

`WinHover` attaches a hover callback to compatible child controls:

```swift
let hover = WinHover { isHovered in
    print(isHovered ? "entered" : "exited")
}
hover.add(WinButton("Settings") {})
root.add(hover)
```

Current implementation: callbacks are registered for child HWND controls that
already participate in SwiftWin's mouse tracking. Arbitrary layout-region
hover is planned after the layout engine grows real hit-testing.

## Choosing Colors

`WinColorPicker` provides a traditional color-picking control:

```swift
let accentColor = WinColorPicker("Accent color", color: .accent) { color in
    print("New RGB color: \(color.red), \(color.green), \(color.blue)")
}
```

Current implementation: clicking the control opens the Windows common color
dialog and repaints the owner-drawn swatch when the user accepts a color. The
dialog uses Win32 `COLORREF` values internally, while SwiftWinLegacy exposes a
plain RGB `WinForegroundStyle`.

## Choosing Dates

`WinDatePicker` provides a traditional date-only picker:

```swift
let launchDate = WinDatePicker(
    "Launch date",
    date: WinDate(year: 2026, month: 5, day: 23)
) { date in
    print("Selected date: \(date.year)-\(date.month)-\(date.day)")
}
```

Windows dispatches Date Time Picker changes through `WM_NOTIFY` and reports the
value as `SYSTEMTIME`. SwiftWinLegacy maps that into `WinDate` so app code can
stay plain Swift. The native control uses segmented keyboard entry; on systems
with a keyboard Clear key, Clear switches it into direct numeric entry. Time
selection, date ranges, and `Foundation.Date` helpers are future work.

## Opening Links

`WinLink` opens destinations through the Windows Shell API:

```swift
root.add(WinLink("Open Swift.org", destination: "https://www.swift.org"))
```

Windows dispatches the destination to the user's default browser or protocol
handler. This is why `SwiftWinLegacy` links `shell32` on Windows.
