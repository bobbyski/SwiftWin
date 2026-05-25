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

Use `role: .cancel` for commands that should respond to Escape:

```swift
Button("Cancel", role: .cancel) {
    Dialog.show(title: "Cancel", message: "Cancelled.")
}
```

Available button roles:

- `.cancel`
- `.destructive`

Current implementation: buttons are owner-drawn in the Win32 renderer, so primary and secondary buttons have visibly different styling. Owner-drawn buttons also support basic pressed, disabled, focused, and hover paint states. The first primary button acts as the default Enter command. Buttons marked `role: .cancel`, and currently buttons literally titled `Cancel`, act as Escape commands. Destructive role metadata exists, but destructive-specific styling and accessibility are still planned.

## Link

`Link` renders clickable external link text.

```swift
Link("Open Swift.org", destination: "https://www.swift.org")
```

The traditional API exposes the same concept as `WinLink`:

```swift
let link = WinLink("Open Swift.org", destination: "https://www.swift.org")
```

Windows note for Apple developers: opening a URL is handled through the Windows
Shell API, not the window/control API. SwiftWinLegacy uses `ShellExecuteW`, so
Windows dispatches the destination to the user's default browser or protocol
handler. That also means the package must link `shell32` on Windows.

Current implementation: links are owner-drawn clickable controls with link-like
text color, underline, hover, and pressed states. The first SwiftWinUI
initializer accepts string destinations because importing `Foundation.URL`
currently trips the ARM64 Windows UCRT overlay issue in this toolchain. A
SwiftUI-compatible `URL` initializer remains planned.

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

## SecureField

`SecureField` renders a password-style single-line editable text control.

```swift
@State private var accessCode = ""

SecureField("Access code", text: $accessCode)
    .frame(width: 380)
Text("Access code: \(accessCode.isEmpty ? "missing" : "set")", style: .caption)
```

The traditional API exposes the same concept as `WinSecureField`:

```swift
let accessCode = WinSecureField("Access code", text: "")
```

Current implementation: the Win32 backend uses an `EDIT` control with
`ES_PASSWORD`, so typed characters are masked by Windows. The value still
exists as a normal Swift string in the app process. Console renderers redact the
value by default, but reveal controls, submit handling, clipboard policy, and
stronger credential-management helpers remain future work.

## TextEditor

`TextEditor` renders a multi-line editable text area.

```swift
@State private var notes = "Milestone notes"

TextEditor("Notes", text: $notes)
    .frame(width: 380, height: 96)
Text("Notes: \(notes.count) characters", style: .caption)
```

The traditional API exposes the same concept as `WinTextEditor`:

```swift
let notes = WinTextEditor("Notes", text: "Milestone notes")
```

Current implementation: the Win32 backend uses a multiline `EDIT` child window
with vertical scrolling, return-key entry, callback changes, binding changes,
and imperative refresh support. Placeholder cue banners are not reliable for
multiline Win32 edit controls, so the prompt is currently semantic and should
later feed accessibility metadata. Rich text, selection APIs, find/replace,
syntax highlighting, and serious document editing remain future work.

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

## ColorPicker

`ColorPicker` renders a small color swatch control.

```swift
@State private var accentColor = Color.accent

ColorPicker("Accent color", selection: $accentColor)
Text("Accent color: \(accentColor.red), \(accentColor.green), \(accentColor.blue)", style: .caption)
    .foregroundStyle(accentColor)
```

The traditional API exposes the same concept as `WinColorPicker`:

```swift
let accentColor = WinColorPicker("Accent color", color: .accent)
```

Current implementation: this is an owner-drawn swatch button backed by the
Windows common color dialog. Clicking the control opens `ChooseColorW`, updates
callback or binding state when the dialog is accepted, and preserves the current
demo palette as custom dialog presets. SwiftUI's richer color model, opacity,
color spaces, and inline picker styles remain planned.

## DatePicker

`DatePicker` renders a date-only picker.

```swift
@State private var launchDate = CalendarDate(year: 2026, month: 5, day: 23)

DatePicker("Launch date", selection: $launchDate)
Text("Launch date: \(launchDate.year)-\(launchDate.month)-\(launchDate.day)", style: .caption)
```

The traditional API exposes the same concept as `WinDatePicker`:

```swift
let launchDate = WinDatePicker(
    "Launch date",
    date: WinDate(year: 2026, month: 5, day: 23)
)
```

Windows note for Apple developers: the Win32 Date Time Picker sends selection
changes through `WM_NOTIFY`, not `WM_COMMAND`, and its native value is a
`SYSTEMTIME` struct. Its text entry is also segmented by default; use arrow-key
style editing, or press the keyboard Clear key on systems that expose it before
direct numeric entry. SwiftWin hides the native value plumbing behind
`CalendarDate` and `WinDate`.

Current implementation: this is a date-only first pass backed by the Win32
`SysDateTimePick32` common control. SwiftUI-compatible `Foundation.Date`
bindings, displayed-component options, ranges, time selection, and locale-aware
formatting remain planned.

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

## ScrollView

`ScrollView` creates a vertical scroll container.

```swift
ScrollView {
    VStack(spacing: 14) {
        TextField("Project name", text: $projectName)
        TextEditor("Notes", text: $notes)
        Slider("Scale", value: $scale, range: 0...100)
    }
}
.frame(width: 760, height: 360)
```

The traditional API exposes the same concept as `WinScrollView`:

```swift
let scrollView = WinScrollView(width: 760, height: 360)
scrollView.add(content)
root.add(scrollView)
```

Current implementation: this is a first-pass vertical container. The Win32
backend records the child HWNDs created inside the scroll view, moves them in
response to mouse-wheel scrolling, and hides children outside the viewport.
Native scrollbar thumbs, nested scroll views, stronger clipping, scroll
indicators, and full SwiftUI axis/indicator options remain planned.

## Accessibility Metadata

SwiftWinUI supports first-pass accessibility metadata modifiers:

```swift
TextField("Project name", text: $projectName)
    .accessibilityLabel("Project name")
    .accessibilityRole(.textField)
    .accessibilityValue(projectName)
```

Supported metadata hooks:

- `.accessibilityLabel(_:)`
- `.accessibilityValue(_:)`
- `.accessibilityRole(_:)`
- `.accessibilityHint(_:)`

The traditional API exposes the same concept as `WinAccessibility`:

```swift
let metadata = WinAccessibility(
    WinAccessibilityMetadata(label: "Project name", role: .textField)
)
metadata.add(projectName)
```

Current implementation: the Win32 backend records merged metadata per child
control ID. This is not a full Windows UI Automation provider yet, so screen
readers should not be expected to receive all metadata until the UIA bridge is
implemented.

## Hover

`.onHover(perform:)` observes pointer entry and exit for compatible controls.

```swift
@State private var hoverTarget = "None"

Button("Settings") {
    Dialog.show(title: "Settings", message: "Hovered: \(hoverTarget)")
}
.onHover { isHovered in
    hoverTarget = isHovered ? "Settings" : "None"
}
```

The traditional API exposes the same concept as `WinHover`:

```swift
let hover = WinHover { isHovered in
    print(isHovered ? "entered" : "exited")
}
hover.add(WinButton("Settings") {})
```

Current implementation: the Win32 backend attaches hover callbacks to native
child controls that already use SwiftWin's control tracking. This covers the
current owner-drawn controls and command controls. Region hover for arbitrary
layout containers is planned with the real layout and hit-testing engine.

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

Current implementation: state writes schedule renderer invalidation. Binding-backed controls also carry provider closures so the Win32 renderer can refresh existing native text fields, secure fields, text editors, toggles, pickers, sliders, steppers, color pickers, date pickers, dynamic text, and progress bars without recreating the window. The traditional `SwiftWinLegacy` layer also exposes `refresh()` on its mutable form controls for imperative code-driven changes.

Dynamic `Text` values also refresh through the current invalidation hook. The
Win32 backend refreshes these labels after `TextField`, `SecureField`, `TextEditor`, `Toggle`, `Picker`,
`Slider`, `Stepper`, `ColorPicker`, and `DatePicker` changes, which is enough for current live previews and
simple inline validation:

```swift
@State private var scale = 50

Slider("Scale", value: $scale, range: 0...100)
Text("Live scale preview: \(scale)", style: .caption)
```

```swift
TextField("Project name", text: $projectName)
Text(projectName.isEmpty ? "Project name is required." : "", style: .caption)
    .foregroundStyle(.destructive)
```

This is a narrow bridge toward SwiftUI-style body invalidation, not a full diffing engine yet. Layout-affecting state changes still need real reconciliation and measure/place work.

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

Windows note for Apple developers: static text color is handled through the parent window's `WM_CTLCOLORSTATIC` message, not by setting a direct property on the `STATIC` child control. That is why SwiftWinLegacy stores text color metadata and answers Windows during painting. Plain labels default to a transparent rectangle by returning a Win32 `NULL_BRUSH`; only explicit background panels return a solid brush. Trackbars also report through this paint path, but they still need a real brush or Windows can paint black or blank slider rectangles. SwiftWinLegacy handles that internally with a control-surface brush so slider callers get the polished default behavior.

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
- `WinColorControl`
- `WinDateControl`

These protocols are intentionally small. They let future custom controls, test doubles, alternate app runners, and future renderers interoperate with the default `WinApplication`, `WinStack`, `WinText`, `WinTextField`, `WinSecureField`, `WinTextEditor`, and `WinButton` implementations.
