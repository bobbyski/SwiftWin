# SwiftWinUI

SwiftWinUI is an experimental SwiftUI-compatible UI framework for building native Windows desktop apps in Swift.

The goal is to make SwiftUI-style app code feel as close to real SwiftUI as Windows and the available Swift toolchain allow. Full compatibility may not be achievable, but compatibility is the design target: matching SwiftUI names, concepts, builder behavior, state model, modifiers, and layout semantics wherever practical.

SwiftWinUI renders the declarative view tree through backend renderers. The current Windows backend creates a real Win32 window with native and owner-drawn controls, while the console renderer prints the UI tree for diagnostics.

> Status: early prototype. It opens native windows, lays out basic views, wires button actions, and shows native dialogs. It is not production-ready yet.

## Design Philosophy

SwiftWinUI and SwiftWinLegacy are intentionally protocol-oriented. Public behavior should be described by small protocols first when that improves type safety, interoperability, or future customization. Concrete controls such as `WinButton` and `WinStack` should be default implementations, not permanent dead ends.

Functions should stay as small as reasonably practical. When an implementation starts mixing platform declarations, layout, rendering, resource ownership, and event routing, that is a sign to split it into clearer protocol-backed components.

## Features

- Parallel libraries: `SwiftWinLegacy` for traditional imperative UI, `SwiftWinUI` for SwiftUI-compatible declarative UI
- SwiftUI-oriented declarative API with `App`, `WindowGroup`, `VStack`, `HStack`, `Text`, `TextField`, `SecureField`, `TextEditor`, `Toggle`, `Picker`, `Slider`, `Stepper`, `ColorPicker`, `DatePicker`, `ProgressView`, `Link`, `Button`, and `Spacer`
- Traditional Swift API with `WinApplication`, `WinWindow`, `WinStack`, `WinText`, `WinTextField`, `WinSecureField`, `WinTextEditor`, `WinToggle`, `WinPicker`, `WinSlider`, `WinStepper`, `WinColorPicker`, `WinDatePicker`, `WinProgressView`, `WinLink`, `WinButton`, `WinSpacer`, and `WinDialog`
- Early form input with `TextField`, `SecureField`, `TextEditor`, `Toggle`, `Picker`, `Slider`, `Stepper`, dialog-backed `ColorPicker`, date-only `DatePicker`, and determinate `ProgressView`
- Protocol-oriented traditional API with extension points for app runners, containers, text displays, titled controls, action controls, and buttons
- Native Windows backend using Win32 APIs
- Console renderer for inspecting rendered view trees
- Button actions routed through Win32 `WM_COMMAND`
- Basic button styles: `.primary` and `.secondary`
- Native Windows dialogs through `Dialog.show(...)`
- Renderer boundary designed for future Win32, WinUI, or Direct2D backends

## User Documentation

User-facing documentation lives in [userDocs](userDocs/README.md).

The traditional API also has a GitHub-style README at [SwiftWinLegacy/README.md](SwiftWinLegacy/README.md).

## Compatibility Goal

SwiftWinUI should prefer SwiftUI-compatible surface area over custom API design.

Compatibility priorities:

1. Source compatibility for common SwiftUI app structure and view declarations.
2. Matching control and layout names where behavior can be made close enough.
3. Matching modifier names and chaining style.
4. Matching state and binding concepts.
5. Matching behavior where Windows can support it cleanly.
6. Documented compatibility gaps where Windows, SwiftPM, or the current backend requires different behavior.

When a feature cannot be implemented exactly like SwiftUI, the framework should keep the closest SwiftUI-shaped public API and isolate platform-specific behavior behind the renderer.

## Quick Start

Clone or open the package directory:

```powershell
cd C:\AIResearch\SwiftWin\Code\SwiftWinUI
```

Build the package:

```powershell
swift build
```

Run the demo:

```powershell
.\.build\aarch64-unknown-windows-msvc\debug\SwiftWinUIDemo.exe
```

On Windows, the demo opens a native Win32 window. Click `Create Window` or `Settings` to verify button actions and native dialogs.

Windows batch shortcuts are available for sanity checks:

```bat
buildandrun.bat          rem build and run SwiftWinUIDemo
buildandrun.bat legacy   rem build and run SwiftWinLegacyDemo
run.bat                  rem run the previously built SwiftWinUIDemo
run.bat legacy           rem run the previously built SwiftWinLegacyDemo
```

Unix-like shell shortcuts are also available for macOS, Linux, or Windows shells that actually provide `sh`:

```sh
sh ./buildandrun.sh          # build and run SwiftWinUIDemo
sh ./buildandrun.sh legacy   # build and run SwiftWinLegacyDemo
sh ./run.sh                  # run the previously built SwiftWinUIDemo
sh ./run.sh legacy           # run the previously built SwiftWinLegacyDemo
```

Windows note: SwiftPM currently writes debug executables under a target-triple path such as `.build/aarch64-unknown-windows-msvc/debug`. The scripts check that Windows shape as well as the usual `.build/debug` layout used on macOS and Linux.

## Example

```swift
import SwiftWinUI

struct DemoApp: App {
    var body: some Scene {
        WindowGroup("SwiftWinUI Demo") {
            VStack(spacing: 14) {
                Text("SwiftWinUI", style: .title)
                Text("A Swift-first framework for Windows desktop apps.")
                TextField("Project name", text: "SwiftWin")
                Toggle("Include diagnostics", isOn: true)
                Picker("Theme", options: ["System", "Light", "Dark"])
                ColorPicker("Accent color", color: .accent)
                DatePicker("Launch date", date: CalendarDate(year: 2026, month: 5, day: 23))
                Slider("Scale", value: 50, range: 0...100)
                Stepper("Quantity", value: 2, range: 0...10, variant: .integratedValue)
                ProgressView("Scale progress", value: 50, total: 100)

                HStack(spacing: 10) {
                    Button("Create Window", style: .primary) {
                        Dialog.show(
                            title: "Create Window",
                            message: "Button actions are wired through Win32 command routing."
                        )
                    }

                    Button("Settings") {
                        Dialog.show(
                            title: "Settings",
                            message: "Next stop: real settings controls and state."
                        )
                    }
                }

                Spacer()
                Text("Native Win32 backend: active.", style: .caption)
            }
        }
    }
}

DemoApp.main()
```

## Console Renderer

Use `ConsoleRenderer` when you want to inspect the declarative view tree instead of opening a native window:

```swift
DemoApp.main(renderer: ConsoleRenderer())
```

Example output:

```text
Window(title: SwiftWinUI Demo, size: 960x640)
  VStack(spacing: 14.0)
    Text("SwiftWinUI", size: 24.0, weight: semibold)
    Text("A Swift-first framework for Windows desktop apps that can finally open real windows.", size: 14.0, weight: regular)
    HStack(spacing: 10.0)
      Button("Create Window", style: primary)
      Button("Settings", style: secondary)
    Spacer()
    Text("Native Win32 backend: active. Console renderer: still available for diagnostics.", size: 12.0, weight: regular)
```

## Project Layout

```text
SwiftWinUI
  Package.swift
  Sources
    SwiftWinLegacy
      Core                  # application/window types and protocols
      Controls              # traditional controls such as WinText and WinButton
      Platform/Win32        # native Win32 runtime, declarations, message handling
      Rendering             # diagnostic console renderer
    SwiftWinLegacyDemo
      main.swift             # Traditional API demo
    SwiftWinUI
      Application.swift      # App, Scene, WindowGroup, runtime entry point
      View.swift             # View protocol, renderer protocol, result builder
      Controls              # declarative controls such as Text and Button
      Dialog.swift           # Cross-platform dialog facade
      ConsoleRenderer.swift  # Diagnostic tree renderer
      Win32Renderer.swift    # Native Windows renderer
    SwiftWinUIDemo
      main.swift             # Demo app
  Tests
    SwiftWinUITests
      SwiftWinUITests.swift
```

## Architecture

SwiftWinUI now has two public layers:

- `SwiftWinLegacy`: traditional imperative Swift API and current native Win32 implementation.
- `SwiftWinUI`: SwiftUI-compatible declarative API that depends on and wraps `SwiftWinLegacy`.

```text
SwiftWinUI App
  -> App / Scene / View tree
  -> Win32Renderer adapter
  -> SwiftWinLegacy objects
  -> Win32 runtime

SwiftWinLegacy App
  -> WinApplication / WinWindow / WinElement tree
  -> Win32 runtime
```

This keeps the SwiftUI-compatible API focused on compatibility while the traditional layer owns imperative controls, events, and native runtime behavior. The native runtime currently uses hand-declared Windows APIs to avoid relying on `WinSDK` imports in toolchains where the Windows SDK module is unstable.

The codebase should keep moving toward smaller files and smaller functions: public protocols and model types, layout, native control creation, event routing, and Win32 declarations should become separate pieces as the framework grows.

## Requirements

- Windows
- Swift toolchain for Windows
- Windows SDK and MSVC linker tools available to SwiftPM

The project has been exercised with an ARM64 Windows Swift snapshot. If `swift` is not visible in a fresh shell, open a developer shell or make sure the Swift toolchain `usr\bin` directory is on `PATH`.

## Windows Notes For Apple Developers

If you come from macOS or iOS development, these Windows concepts are worth keeping in mind:

- `HWND` is the native window/control handle. Many Windows controls are child windows, not just lightweight views.
- The message loop is explicit. Events arrive as messages such as `WM_COMMAND`, `WM_DRAWITEM`, and `WM_DESTROY`.
- Win32 drawing often uses GDI handles such as `HDC`, `HBRUSH`, `HPEN`, and `HFONT`. These are resources that must eventually be managed carefully.
- Dynamic libraries are linked by name, such as `user32`, `gdi32`, `kernel32`, and `uxtheme`.
- Web views use Microsoft Edge WebView2, not `WKWebView`. WebView2 is Chromium/Blink-based and supports modern browser content including WebAssembly.
- Many modern Windows APIs use COM interfaces. WebView2 in particular is COM-heavy, so Swift may need a C/C++ shim or carefully declared COM bindings.
- DPI behavior is not automatic in the same way AppKit/UIKit developers might expect. Windows apps need deliberate DPI awareness and scaling.
- Runtime distribution matters. WebView2 can use an Evergreen Runtime installed on the machine or a Fixed Version Runtime bundled with the app.
- Controls may look different depending on OS version, theme, high contrast settings, and whether they are native, themed, or owner-drawn.
- File paths, process launching, and shell behavior differ sharply between PowerShell, Developer Command Prompt, and app-launched processes.

## Tests

Run:

```powershell
swift test
```

Known issue: some ARM64 Windows Swift snapshots fail while importing XCTest because the toolchain cannot build the UCRT overlay module. In that case, `swift build` is the current verification path for the framework and demo.

## Current Limitations

- Layout is basic stack positioning, not a full measurement and constraint system.
- Styling is still native Win32 control styling, with only light polish applied.
- No state system yet, such as `@State` or observable models.
- SwiftUI compatibility is currently aspirational and partial.
- No list, image, menu, or grid controls yet. Text input and core form controls are in progress.
- Win32 API declarations are intentionally minimal and local to the renderer.
- The visual design is functional prototype quality, not modern custom UI yet.

## Roadmap

- Add a real layout engine with measurement, alignment, and DPI scaling
- Add SwiftUI-compatible state primitives such as `@State`, `Binding`, and event-driven invalidation
- Add common SwiftUI modifiers such as `.padding`, `.frame`, `.font`, `.foregroundStyle`, `.background`, and `.disabled`
- Add `TextField`, `Toggle`, `List`, `Image`, menus, and dialogs as first-class views
- Improve rendering with custom-drawn controls or a Direct2D backend
- Add accessibility metadata and keyboard traversal
- Add screenshot or tree snapshot tests once the Windows test runner is reliable
- Explore a future WinUI backend behind the same `Renderer` protocol

## License

MIT. Copyright (c) 2026 Bobby Skinner. All rights reserved.
