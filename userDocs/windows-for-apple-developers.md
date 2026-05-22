# Windows Notes For Apple Developers

This page explains Windows concepts that may feel unusual if you come from macOS, iOS, AppKit, UIKit, SwiftUI, or `WKWebView`.

## HWND

`HWND` is the native Windows handle for both top-level windows and many controls.

On Apple platforms, you may think in terms of `NSWindow`, `NSView`, `UIView`, or SwiftUI views. In Win32, many controls are actual child windows with their own `HWND`.

## Message Loop

Win32 apps receive events through a message loop.

Examples:

- `WM_COMMAND`: button clicks and command events
- `WM_DRAWITEM`: owner-drawn control rendering
- `WM_CTLCOLORSTATIC`: static text color/background customization
- `WM_DESTROY`: window teardown

This is lower-level than SwiftUI actions or AppKit delegate callbacks.

## GDI Resources

Win32 drawing often uses GDI handles:

- `HDC`: drawing context
- `HBRUSH`: fill brush
- `HPEN`: stroke pen
- `HFONT`: font

These resources need careful lifetime management. SwiftWinUI currently creates some of these resources directly in `Win32Renderer`; cleanup and ownership need more work.

## DLL Linking

Windows APIs are grouped into import libraries.

Current examples:

- `user32`: windows, messages, controls, dialogs
- `gdi32`: drawing, fonts, brushes, pens
- `kernel32`: core process/module APIs
- `uxtheme`: theming APIs

SwiftPM links these by name in `Package.swift`.

## COM

Many Windows APIs use COM interfaces. WebView2 is COM-heavy.

For SwiftWinUI, this means WebView2 may need:

- hand-declared COM bindings,
- generated bindings from headers or IDL,
- or a small C/C++ shim target.

## WebView2 Versus WKWebView

Windows does not use `WKWebView`.

The closest native equivalent is Microsoft Edge WebView2. It embeds the Edge/Chromium runtime and supports modern web content, including browser WebAssembly.

## DPI

Windows DPI handling is explicit. Apps need deliberate DPI awareness and scaling. Do not assume coordinates or font sizes behave like AppKit/UIKit/SwiftUI.

## Runtime Distribution

Some Windows features depend on separately installed runtimes.

For WebView2, apps can use:

- Evergreen Runtime: installed and updated on the machine.
- Fixed Version Runtime: bundled with the app for reproducibility.

## Shells And PATH

PowerShell, Developer Command Prompt, app-launched processes, and Codex tool shells can have different `PATH` values. A command that works in one shell may not resolve in another.
