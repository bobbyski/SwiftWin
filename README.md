# SwiftWinUI

SwiftWinUI is a Swift-first framework design for building Windows desktop interfaces. The package starts with a declarative API inspired by SwiftUI, but keeps platform work behind a renderer boundary so native Windows backends can evolve without changing application code.

```swift
import SwiftWinUI

struct DemoApp: App {
    var body: some Scene {
        WindowGroup("Demo") {
            VStack {
                Text("Hello, Windows", style: .title)
                Button("Continue") {
                    print("Clicked")
                }
            }
        }
    }
}

DemoApp.main()
```

## Build and Run

From the package directory:

```powershell
cd C:\AIResearch\SwiftWin\Code\SwiftWinUI
swift build
```

Run the demo app:

```powershell
.\.build\aarch64-unknown-windows-msvc\debug\SwiftWinUIDemo.exe
```

On Windows this opens a native Win32 window with the demo controls. The process stays running until you close the window.

To inspect the declarative UI tree in the console instead, call the app with `ConsoleRenderer`:

```swift
DemoApp.main(renderer: ConsoleRenderer())
```

That diagnostic renderer prints output like this:

```text
Window(title: SwiftWinUI Demo, size: 960x640)
  VStack(spacing: 12.0)
    Text("SwiftWinUI", size: 24.0, weight: semibold)
    Text("A Swift-first framework for Windows desktop interfaces.", size: 14.0, weight: regular)
    HStack(spacing: 8.0)
      Button("Create Window")
      Button("Settings")
    Spacer()
    Text("Renderer boundary is ready for Win32 or WinUI.", size: 12.0, weight: regular)
```

Run tests:

```powershell
swift test
```

On the current ARM64 Windows Swift snapshot, `swift test` may fail while importing XCTest because the toolchain cannot build the UCRT overlay module. The framework and demo still build with `swift build`.

## Layers

- `App` and `Scene`: application entry point and top-level window ownership.
- `View`: declarative UI tree made from controls and layout containers.
- `Renderer`: backend contract for native Windows rendering.
- `ConsoleRenderer`: development renderer for testing tree output.
- `Win32Renderer`: Windows-only backend placeholder prepared for native HWND, layout, and message loop work.

## Backend Direction

The first native backend should target Win32 because it is available from Swift on Windows through `WinSDK` and gives direct access to HWND creation, message dispatch, controls, DPI, and accessibility hooks. A later WinUI backend can reuse the same `Renderer` protocol if XAML Islands or the Windows App SDK become available in the toolchain.
