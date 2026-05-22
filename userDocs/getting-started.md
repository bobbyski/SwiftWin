# Getting Started

This guide shows how to build and run the current SwiftWinUI demo.

## Requirements

- Windows
- Swift toolchain for Windows
- Windows SDK and MSVC linker tools available to SwiftPM

If `swift` is not available in a fresh shell, open a Developer Command Prompt or make sure the Swift toolchain `usr\bin` directory is on `PATH`.

## Build

From the package directory:

```powershell
cd C:\AIResearch\SwiftWin\Code\SwiftWinUI
swift build
```

## Run The Demo

```powershell
.\.build\aarch64-unknown-windows-msvc\debug\SwiftWinUIDemo.exe
```

The demo opens a native Win32 window. Click `Create Window` or `Settings` to verify button actions and native dialogs.

## Sanity Scripts

The package includes Windows batch scripts for quick manual testing:

```bat
buildandrun.bat          rem build and run SwiftWinUIDemo
buildandrun.bat legacy   rem build and run SwiftWinLegacyDemo
run.bat                  rem run the previously built SwiftWinUIDemo
run.bat legacy           rem run the previously built SwiftWinLegacyDemo
```

Unix-like shell scripts are also available for macOS, Linux, or Windows shells that actually provide `sh`:

```sh
sh ./buildandrun.sh          # build and run SwiftWinUIDemo
sh ./buildandrun.sh legacy   # build and run SwiftWinLegacyDemo
sh ./run.sh                  # run the previously built SwiftWinUIDemo
sh ./run.sh legacy           # run the previously built SwiftWinLegacyDemo
```

Windows note: SwiftPM debug executables usually live under a target-triple path such as `.build/aarch64-unknown-windows-msvc/debug`. The scripts check that Windows layout as well as the usual `.build/debug` layout used on macOS and Linux.

## Use The Console Renderer

The console renderer prints the declarative UI tree instead of opening a native window.

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

## Tests

```powershell
swift test
```

Known issue: some ARM64 Windows Swift snapshots fail while importing XCTest because the toolchain cannot build the UCRT overlay module. For now, `swift build` is the reliable verification path for the framework and demo.
