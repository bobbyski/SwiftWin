# Roadmap

This roadmap summarizes the current direction. The detailed living plan is in [../PLAN.md](../PLAN.md).

## Phase I: SwiftUI-Compatible Declarative Framework

Goal: make SwiftUI-style app code work on Windows with maximum practical compatibility.

Current status:

- Basic `App` and `WindowGroup`
- Basic `View` and `ViewBuilder`
- `Text`, `Button`, `Spacer`, `VStack`, `HStack`
- Native Win32 renderer
- Console renderer
- Owner-drawn primary and secondary buttons
- Native dialogs

Next work:

- Add modifiers such as `.padding`, `.frame`, `.font`, `.foregroundStyle`, `.background`, and `.disabled`
- Add state primitives such as `@State` and `Binding`
- Add a real layout engine
- Add common controls such as `TextField`, `Toggle`, `List`, and `Image`
- Add `WebView` backed by WebView2

## Phase II: Traditional Swift Framework

Goal: add a non-declarative Swift API for Windows UI.

This may be built in parallel if it makes Phase I easier. The declarative layer could wrap the traditional layer internally.

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

- console snapshot tests
- layout tests
- native smoke tests
- screenshot checks
