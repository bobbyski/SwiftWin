# Current API Guide

This page documents the public API that exists today.

## App

Apps conform to `App` and provide a `body` containing a `Scene`.

```swift
import SwiftWinUI

struct DemoApp: App {
    var body: some Scene {
        WindowGroup("SwiftWinUI Demo") {
            Text("Hello, Windows")
        }
    }
}

DemoApp.main()
```

On Windows, `DemoApp.main()` uses `Win32Renderer` by default. On other platforms, it falls back to `ConsoleRenderer`.

## WindowGroup

`WindowGroup` creates a top-level app window.

```swift
WindowGroup("My App", width: 960, height: 640) {
    Text("Hello")
}
```

Current limitation: only one simple window path is implemented. Multiple windows and window lifecycle callbacks are planned.

## Text

`Text` renders static text.

```swift
Text("SwiftWinUI")
Text("Title", style: .title)
Text("Caption", style: .caption)
```

Available text styles:

- `.title`
- `.body`
- `.caption`

## Button

`Button` renders a clickable control and executes a closure.

```swift
Button("Settings") {
    Dialog.show(title: "Settings", message: "Settings clicked.")
}
```

Use `.primary` for the main action:

```swift
Button("Create Window", style: .primary) {
    Dialog.show(title: "Create Window", message: "Clicked.")
}
```

Available button styles:

- `.primary`
- `.secondary`

Current implementation: buttons are owner-drawn in the Win32 renderer, so primary and secondary buttons have visibly different styling.

## Stacks

`VStack` and `HStack` place child views vertically or horizontally.

```swift
VStack(spacing: 14) {
    Text("Title", style: .title)

    HStack(spacing: 10) {
        Button("OK") {}
        Button("Cancel") {}
    }
}
```

Current limitation: layout is basic direct placement. A real measure/place layout engine is planned.

## Spacer

`Spacer` inserts fixed spacing in the current stack.

```swift
Spacer()
```

Current limitation: this is not yet a SwiftUI-compatible flexible spacer.

## Dialog

`Dialog.show` displays a native Windows message box.

```swift
Dialog.show(
    title: "Hello",
    message: "This is a native dialog."
)
```

On non-Windows platforms, it currently prints to the console.

## Renderers

SwiftWinUI uses a renderer boundary.

- `Win32Renderer`: native Windows renderer.
- `ConsoleRenderer`: diagnostic renderer that prints the UI tree.

```swift
DemoApp.main(renderer: ConsoleRenderer())
```

## SwiftWinLegacy Protocols

The traditional layer now exposes focused protocols for extension points:

- `WinApplicationRunning`
- `WinContainer`
- `WinTextDisplaying`
- `WinTitledControl`
- `WinActionControl`
- `WinButtonDisplaying`

These protocols are intentionally small. They let future custom controls, test doubles, alternate app runners, and future renderers interoperate with the default `WinApplication`, `WinStack`, `WinText`, and `WinButton` implementations.
