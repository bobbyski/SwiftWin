# SwiftWinLegacy

SwiftWinLegacy is the traditional, non-declarative Swift interface for SwiftWin.

It is designed to be used directly by developers who prefer imperative UI programming and to serve as the implementation foundation for the SwiftUI-compatible `SwiftWinUI` layer.

## Status

Early prototype. The first milestone is implemented: `SwiftWinLegacyDemo` reproduces the current SwiftWinUI demo with an imperative API.

## Design Principles

SwiftWinLegacy should stay traditional and explicit while still being protocol-oriented where that creates useful extension points. Public behavior is starting to be represented by small protocols such as `WinApplicationRunning`, `WinContainer`, `WinTextDisplaying`, `WinTitledControl`, `WinActionControl`, and `WinButtonDisplaying`.

Functions should stay as small as reasonably practical. As the Windows backend grows, platform declarations, layout, resource ownership, control creation, drawing, and event routing should be split into focused implementation pieces.

## Example

```swift
import SwiftWinLegacy

let window = WinWindow(title: "SwiftWinLegacy Demo", width: 960, height: 640)
let root = WinStack(axis: .vertical, spacing: 14)

root.add(WinText("SwiftWinLegacy", style: .title))
root.add(WinText("A traditional Swift interface wrapping native Windows UI."))

let buttons = WinStack(axis: .horizontal, spacing: 10)
buttons.add(WinButton("Create Window", style: .primary) {
    WinDialog.show(title: "Create Window", message: "Clicked.")
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

## Build And Run

From the package root:

```powershell
swift build
.\.build\aarch64-unknown-windows-msvc\debug\SwiftWinLegacyDemo.exe
```

## Relationship To SwiftWinUI

`SwiftWinUI` now depends on `SwiftWinLegacy`. The current Win32 renderer in `SwiftWinUI` adapts declarative `Text`, `Button`, `VStack`, `HStack`, and `Spacer` calls into `SwiftWinLegacy` objects, then runs a `WinApplication`.

This lets the traditional framework and SwiftUI-compatible framework evolve simultaneously.

## License

MIT. Copyright (c) Bobby Skinner.
