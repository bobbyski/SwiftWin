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

## TextField

`TextField` renders a single-line editable text control.

```swift
TextField("Project name", text: "SwiftWin") { value in
    print("Project name changed to \(value)")
}
```

Current implementation: this is the first Milestone 2 form control. It uses an initial text value and an `onChange` callback. A SwiftUI-compatible `Binding` initializer is planned once the state system exists.

## Toggle

`Toggle` renders a checkbox-style boolean control.

```swift
Toggle("Include diagnostics", isOn: true) { value in
    print("Diagnostics: \(value)")
}
```

Current implementation: this uses an initial boolean value and an `onChange` callback. A `Binding` initializer is planned.

## Picker

`Picker` renders a segmented selection control.

```swift
Picker("Theme", options: ["System", "Light", "Dark"], selectedIndex: 0) { index in
    print("Selected index: \(index)")
}
```

Current implementation: the Win32 backend renders picker options as radio buttons. A more SwiftUI-compatible generic picker with tags is planned after the state layer exists.

## Slider

`Slider` renders an integer range control.

```swift
Slider("Scale", value: 50, range: 0...100) { value in
    print("Scale: \(value)")
}
```

Current implementation: the Win32 backend uses a horizontal scrollbar as the native range control. This avoids a common-controls dependency during the first Milestone 2 pass.

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
- `WinEditableText`
- `WinTitledControl`
- `WinActionControl`
- `WinButtonDisplaying`

These protocols are intentionally small. They let future custom controls, test doubles, alternate app runners, and future renderers interoperate with the default `WinApplication`, `WinStack`, `WinText`, `WinTextField`, and `WinButton` implementations.
