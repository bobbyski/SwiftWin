# WebView And WebAssembly

SwiftWinUI should include a web view.

On Windows, the practical backend is Microsoft Edge WebView2. It is not WebKit-branded, but it is Chromium/Blink-based. Blink forked from WebKit, so it is from the same broad browser-engine family tree and is the standard embedded browser path for modern Windows apps.

## Goal

Add both:

- `WebView`: SwiftUI-compatible declarative wrapper.
- `WinWebView`: future Phase II imperative control.

## Expected Capabilities

- Host web content inside a native SwiftWinUI window.
- Navigate to URLs.
- Load local HTML strings or files.
- Run browser WebAssembly content.
- Exchange messages between Swift and JavaScript.
- Report navigation lifecycle events.
- Support local asset loading for editor-like apps, including Monaco.

## WebAssembly Scope

WebView2 should support browser WebAssembly content, such as:

- Emscripten output
- AssemblyScript output
- Blazor WebAssembly
- Monaco-adjacent web tooling
- JavaScript apps that load `.wasm` modules

This does not automatically mean WASI or server-side WebAssembly APIs. The first target is WebAssembly as supported by the embedded browser runtime.

## Runtime Distribution

WebView2 apps need the WebView2 Runtime.

Options:

- Evergreen Runtime: normal default, updated by Microsoft.
- Fixed Version Runtime: bundled with the app when strict reproducibility matters.

## Open Implementation Questions

- Should WebView2 bindings be generated, hand-declared, or isolated behind a C/C++ shim?
- Should WebView support live in the main package or an optional package/product?
- Should local assets use file URLs, virtual host mapping, or an embedded local server?
- Should the first sample be a simple HTML page, a Monaco editor, or a small WebAssembly demo?

## Apple Developer Translation

Think of WebView2 as the Windows backend equivalent to `WKWebView`, but with Edge/Chromium instead of WebKit.
