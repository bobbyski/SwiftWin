# Roadmap

This roadmap summarizes the current direction. The detailed living plan is in [../PLAN.md](../PLAN.md).

## Phase I: SwiftUI-Compatible Declarative Framework

Goal: make SwiftUI-style app code work on Windows with maximum practical compatibility.

Current status:

- Basic `App` and `WindowGroup`
- Basic `View` and `ViewBuilder`
- `Text`, `Button`, `Spacer`, `VStack`, `HStack`
- `TextField`, `Toggle`, `Picker`, `Slider`, `Stepper`, and determinate `ProgressView`
- Native Win32 renderer
- Console renderer
- Owner-drawn primary and secondary buttons
- Native dialogs

Next work:

- Broaden `Binding` support into more control families
- Continue modifiers such as `.padding`, `.frame`, `.font`, `.foregroundStyle`, `.background`, `.border`, `.cornerRadius`, and `.disabled`
- Continue state primitives beyond `@State` and `Binding`
- Add a real layout engine
- Add common controls such as `List`, `Image`, `SecureField`, `DatePicker`, and `ColorPicker`
- Add `WebView` backed by WebView2
- Keep renderer and layout work protocol-oriented so custom implementations can plug in later

## Phase II: Traditional Swift Framework

Goal: maintain a non-declarative Swift API for Windows UI in parallel with SwiftWinUI.

This is now the selected approach. `SwiftWinLegacy` is a package product and `SwiftWinUI` depends on it. The declarative layer wraps the traditional layer internally for the current Win32 path.

Design rule: keep functions small and use focused protocols for useful extension points. The first protocol contracts now cover app running, containers, text display, titled controls, action controls, and button-like controls.

Candidate shape:

```swift
let app = WinApplication()
let window = WinWindow(title: "SwiftWin Demo", width: 960, height: 640)
let stack = WinStack(axis: .vertical, spacing: 14)

stack.add(WinText("SwiftWin", style: .title))
stack.add(WinButton("Create Window", style: .primary) {
    WinDialog.show(title: "Create Window", message: "Clicked.")
})

window.content = stack
app.run(window)
```

## WebView

Goal: include WebView2 support with WebAssembly-capable content.

Planned:

- `WebView`
- `WinWebView`
- navigation API
- JavaScript bridge
- local asset loading
- WebAssembly sample

## Rendering

Current renderer:

- Win32 with GDI and owner-drawn buttons.

Possible future renderers:

- Direct2D renderer for modern custom UI
- WinUI backend if Swift interop becomes practical

## Testing

Current reliable validation:

```powershell
swift build
```

Planned:

- keep splitting Win32 layout and native control hosting into smaller protocol-backed files as the backend grows
- console snapshot tests
- layout tests
- native smoke tests
- screenshot checks
