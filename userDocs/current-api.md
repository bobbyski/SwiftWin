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

Use the binding initializer for SwiftUI-style state flow:

```swift
@State private var projectName = "SwiftWin"

TextField("Project name", text: $projectName)
```

Current implementation: native edits update the bound value. Full automatic view rerendering is still planned.

## Toggle

`Toggle` renders a checkbox-style boolean control.

```swift
Toggle("Include diagnostics", isOn: true) { value in
    print("Diagnostics: \(value)")
}
```

Binding form:

```swift
@State private var includeDiagnostics = true

Toggle("Include diagnostics", isOn: $includeDiagnostics)
```

Current implementation: the Win32 backend owner-draws the toggle for a cleaner modern appearance.

## Picker

`Picker` renders a segmented selection control.

```swift
Picker("Theme", options: ["System", "Light", "Dark"], selectedIndex: 0) { index in
    print("Selected index: \(index)")
}
```

Binding form:

```swift
@State private var themeIndex = 0

Picker("Theme", options: ["System", "Light", "Dark"], selectedIndex: $themeIndex)
```

Current implementation: the Win32 backend owner-draws picker options as pill-style segmented choices. A more SwiftUI-compatible generic picker with tags is planned.

## Slider

`Slider` renders an integer range control.

```swift
Slider("Scale", value: 50, range: 0...100) { value in
    print("Scale: \(value)")
}
```

Binding form:

```swift
@State private var scale = 50

Slider("Scale", value: $scale, range: 0...100)
```

Current implementation: the Win32 backend uses a Common Controls trackbar and updates its visible value label as the slider moves.

## State And Binding

`@State` stores local mutable state for declarative views, and `Binding` connects controls to that state.

```swift
struct DemoContent: View {
    @State private var projectName = "SwiftWin"

    @ViewBuilder
    var body: some View {
        TextField("Project name", text: $projectName)
    }
}
```

Current limitation: state writes schedule renderer invalidation, but the Win32 renderer does not yet reconcile or rebuild arbitrary dependent views. Buttons and control callbacks read updated state today.

Dynamic `Text` values also refresh through the current invalidation hook:

```swift
@State private var scale = 50

Slider("Scale", value: $scale, range: 0...100)
Text("Live scale preview: \(scale)", style: .caption)
```

This is a narrow bridge toward SwiftUI-style body invalidation, not a full diffing engine yet.

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

## Layout Modifiers

`padding` adds uniform inset around a view.

```swift
VStack(spacing: 14) {
    Text("SwiftWinUI", style: .title)
    Text("Native Windows, Swift-shaped.")
}
.padding(12)
```

`frame(width:height:)` proposes a fixed size to its content.

```swift
TextField("Project name", text: $projectName)
    .frame(width: 340)
```

Current implementation: both modifiers are backed by `SwiftWinLegacy` containers. `frame(width:height:)` is a fixed-size hint used by native control creation; it does not yet implement SwiftUI's full min/max/alignment behavior.

`disabled` disables interactive controls inside a view.

```swift
Button("Disabled") {}
    .disabled()
```

Windows note for Apple developers: disabled state maps to `EnableWindow` on the native child `HWND`. Owner-drawn SwiftWin controls also paint a disabled appearance when Windows reports `ODS_DISABLED`.

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
