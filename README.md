# SwiftWinUI

SwiftWinUI is an experimental SwiftUI-compatible UI framework for building native Windows desktop apps in Swift.

The goal is to make SwiftUI-style app code feel as close to real SwiftUI as Windows and the available Swift toolchain allow. Full compatibility may not be achievable, but compatibility is the design target: matching SwiftUI names, concepts, builder behavior, state model, modifiers, and layout semantics wherever practical.

SwiftWinUI renders the declarative view tree through backend renderers. The current Windows backend creates a real Win32 window with native and owner-drawn controls, while the console renderer prints the UI tree for diagnostics.

> Status: early prototype. It opens native windows, lays out basic views, wires button actions, and shows native dialogs. It is not production-ready yet.

## Features

- SwiftUI-oriented declarative API with `App`, `WindowGroup`, `VStack`, `HStack`, `Text`, `Button`, and `Spacer`
- Native Windows backend using Win32 APIs
- Console renderer for inspecting rendered view trees
- Button actions routed through Win32 `WM_COMMAND`
- Basic button styles: `.primary` and `.secondary`
- Native Windows dialogs through `Dialog.show(...)`
- Renderer boundary designed for future Win32, WinUI, or Direct2D backends

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

## Example

```swift
import SwiftWinUI

struct DemoApp: App {
    var body: some Scene {
        WindowGroup("SwiftWinUI Demo") {
            VStack(spacing: 14) {
                Text("SwiftWinUI", style: .title)
                Text("A Swift-first framework for Windows desktop apps.")

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
    SwiftWinUI
      Application.swift      # App, Scene, WindowGroup, runtime entry point
      View.swift             # View protocol, renderer protocol, result builder
      Controls.swift         # Text, Button, stacks, spacer, styles
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

SwiftWinUI separates the public declarative API from native rendering:

```text
User App
  -> App / Scene
  -> View tree
  -> Renderer protocol
  -> Win32Renderer or ConsoleRenderer
```

This keeps app code stable while the native backend evolves. The Win32 renderer currently uses hand-declared Windows APIs to avoid relying on `WinSDK` imports in toolchains where the Windows SDK module is unstable.

## Requirements

- Windows
- Swift toolchain for Windows
- Windows SDK and MSVC linker tools available to SwiftPM

The project has been exercised with an ARM64 Windows Swift snapshot. If `swift` is not visible in a fresh shell, open a developer shell or make sure the Swift toolchain `usr\bin` directory is on `PATH`.

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
- No text input, list, image, menu, or grid controls yet.
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

No license has been selected yet.
