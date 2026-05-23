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

`font` applies a text style to descendant text, which is the preferred SwiftUI-compatible spelling for inherited typography:

```swift
VStack(spacing: 8) {
    Text("Large section title")
    Text("Supporting copy")
}
.font(.title)
```

An explicit `Text(..., style:)` still wins over an inherited font modifier.

`foregroundStyle` applies an inherited semantic color to descendant text:

```swift
VStack(spacing: 8) {
    Text("SwiftWinUI")
    Text("Native Windows, Swift-shaped.")
}
.foregroundStyle(.secondary)
```

Available text styles:

- `.title`
- `.body`
- `.caption`

Available foreground styles:

- `.primary`
- `.secondary`
- `.accent`
- `.destructive`

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

Current implementation: buttons are owner-drawn in the Win32 renderer, so primary and secondary buttons have visibly different styling. Owner-drawn buttons also support basic pressed, disabled, focused, and hover paint states when Windows reports those states to the draw handler.

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

Current implementation: the Win32 backend owner-draws the toggle for a cleaner modern appearance. The toggle includes basic disabled and hover paint states.

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

Current implementation: the Win32 backend owner-draws picker options as pill-style segmented choices. Picker options include basic selected, disabled, and hover paint states. A more SwiftUI-compatible generic picker with tags is planned.

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

## Stepper

`Stepper` renders an integer increment/decrement control.

```swift
Stepper("Quantity", value: 2, range: 0...10) { value in
    print("Quantity: \(value)")
}
```

Binding form:

```swift
@State private var quantity = 2

Stepper("Quantity", value: $quantity, range: 0...10, variant: .integratedValue)
Text("Quantity preview: \(quantity)", style: .caption)
```

The traditional API exposes the same concept as `WinStepper`:

```swift
let quantity = WinStepper("Quantity", value: 2, range: 0...10, variant: .integratedValue)
```

Current implementation: the Win32 backend renders the compact variant as a value label plus two owner-drawn buttons. The integrated variant renders a title label followed by `- | value | +`. Both variants support integer values, bounds, a positive step amount, callback changes, and binding changes. Numeric text entry, floating-point stepping, and richer SwiftUI label-builder overloads are planned.

## ProgressView

`ProgressView` renders determinate progress.

```swift
@State private var scale = 50

Slider("Scale", value: $scale, range: 0...100)
ProgressView("Scale progress", value: scale, total: 100)
```

The traditional API exposes the same concept as `WinProgressView`:

```swift
let scale = WinSlider("Scale", value: 50, range: 0...100)
let progress = WinProgressView("Scale progress", value: { Double(scale.value) }, total: 100)
```

Current implementation: the Win32 backend uses the Common Controls progress bar. Progress values refresh through the same narrow invalidation bridge used by dynamic text, so progress can follow slider-backed state. Indeterminate progress, ring-style progress, and SwiftUI progress styles are planned.

## Divider

`Divider` renders a separator line.

```swift
VStack(spacing: 12) {
    Text("Details", style: .caption)
    Divider()
    Text("More content")
}
```

Current implementation: the renderer chooses a horizontal separator in vertical stacks and a vertical separator in horizontal stacks. The traditional API exposes this as `WinSeparator(axis:)`.

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

`font` applies an inherited `TextStyle` to descendant text.

```swift
VStack(spacing: 8) {
    Text("SwiftWinUI")
    Text("Native Windows, Swift-shaped.")
}
.font(.body)
```

Current implementation: this supports SwiftWinUI's semantic text styles. It is not yet a full SwiftUI `Font` model with custom families, dynamic type, or weight/design modifiers.

`foregroundStyle` applies an inherited semantic foreground color to text.

```swift
Text("SwiftWinUI", style: .title)
    .foregroundStyle(.accent)
```

Windows note for Apple developers: static text color is handled through the parent window's `WM_CTLCOLORSTATIC` message, not by setting a direct property on the `STATIC` child control. That is why SwiftWinLegacy stores text color metadata and answers Windows during painting.

Current implementation: this is text-only and semantic-color-only. It does not yet support gradients, materials, custom brushes, or automatic dynamic color reconciliation.

`background` paints a solid semantic color behind a view.

```swift
VStack(spacing: 12) {
    Text("SwiftWinUI", style: .title)
    Text("Native Windows, Swift-shaped.")
}
.padding(12)
.background(Color(red: 239, green: 246, blue: 255))
```

Windows note for Apple developers: the current Win32 backend implements this with a child `STATIC` control created before the wrapped controls, then resized after direct-placement layout determines the consumed size. This is more mechanical than SwiftUI's retained rendering model, and it is one reason the future layout/render tree matters.

Current implementation: this supports solid colors only. SwiftUI's arbitrary background views, materials, alignment overloads, clipping, rounded corners, and paint-order semantics remain planned.

`border` paints a solid rectangular border around a view.

```swift
VStack(spacing: 12) {
    Text("SwiftWinUI", style: .title)
    Text("Native Windows, Swift-shaped.")
}
.padding(12)
.background(Color(red: 239, green: 246, blue: 255))
.border(Color(red: 191, green: 219, blue: 254), width: 1)
.cornerRadius(10)
```

Windows note for Apple developers: the current Win32 backend paints the border with a disabled owner-drawn child control created after the wrapped content. Creating it last keeps the border visible; disabling it keeps mouse input flowing to the actual controls below.

`cornerRadius` rounds compatible background and border decorations.

```swift
Text("Rounded panel")
    .padding(12)
    .background(Color(red: 239, green: 246, blue: 255))
    .border(Color(red: 191, green: 219, blue: 254), width: 1)
    .cornerRadius(10)
```

Current implementation: this rounds SwiftWin decoration panels; it does not clip child controls. Shape strokes, overlays, clipping, and precise SwiftUI paint-order behavior remain planned.

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
