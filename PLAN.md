# SwiftWinUI Framework Implementation Plan

## Summary

This plan covers the work needed to grow the current experimental SwiftWinUI package from a focused SwiftPM prototype into a broader Windows UI family with two public layers: Phase I, a SwiftUI-compatible declarative framework, and Phase II, a traditional non-declarative Swift framework that can be used directly or serve as the imperative engine underneath the declarative layer.

The strategic goal is maximum practical SwiftUI compatibility. SwiftWinUI should strive for source-level compatibility with common SwiftUI app code, even though 100% compatibility may not be achievable on Windows. Public API decisions should prefer SwiftUI naming, modifier shape, result-builder behavior, state concepts, layout semantics, and view composition patterns wherever practical. Platform-specific differences should be pushed behind renderer internals or documented as explicit compatibility gaps.

Overall planned-code progress: [###-------] 30%

The implemented base already includes the SwiftPM framework, demo executable, `App` and `WindowGroup` entry point, declarative `View` protocol, `ViewBuilder`, `Text`, `Button`, `Spacer`, `VStack`, `HStack`, text styles, button styles, a renderer protocol boundary, a diagnostic console renderer, a native Win32 renderer, real HWND window creation, native text controls, owner-drawn buttons, button command routing, native message boxes through `Dialog.show`, basic stack positioning, Windows linker settings, and a GitHub-style README. The next architectural steps are to separate layout measurement from rendering, add SwiftUI-compatible state and invalidation, expand the SwiftUI control and modifier catalog in tested batches, make renderer resources safer and more reusable, and decide whether the traditional imperative framework should be built in parallel as the underlying engine for the declarative layer.

Unsupported and partially supported UI capabilities are tracked in [Unsupported SwiftWinUI Coverage](#unsupported-swiftwinui-coverage).

## Project Dashboard

| Phase | Status | Progress | Planned Work | Notes |
| --- | --- | ---: | --- | --- |
| 1: Repository And Package Structure | Implemented | 100% | `Code/SwiftWinUI`, SwiftPM library, demo target, tests folder, README, plan | Package structure exists and builds as a framework plus executable demo. |
| 2: SwiftUI-Compatible API Foundation | Implemented | 60% | `App`, `Scene`, `WindowGroup`, `View`, `ViewBuilder`, `AnyView`, tuple rendering | Core API shape resembles SwiftUI. Needs source-compatibility audit, modifiers, `ForEach`, `Group`, environment, and more result-builder forms. |
| 3: Renderer Boundary | Implemented | 80% | `Renderer` protocol, console renderer, native renderer selection | Public API is separated from backend rendering. Needs a richer render tree and resource lifecycle management. |
| 4: Native Win32 Window Runtime | Implemented | 65% | HWND creation, window class registration, message loop, command routing | Demo opens a native window and buttons work. Needs multiple windows, lifecycle events, errors, and graceful shutdown paths. |
| 5: SwiftUI Control Coverage | In Progress | 20% | `Text`, `Button`, `Spacer`, `Dialog`, planned `WebView` | Buttons are owner-drawn and dialogs work. Most SwiftUI views and controls are not implemented yet. WebView2 should provide the Windows web view path. |
| 6: Layout Engine | In Progress | 20% | stack positioning, spacing, basic child advancement | Current layout is direct placement. Needs measure/place passes, alignment, min/max sizes, wrapping, clipping, and DPI support. |
| 7: Styling And Theming | In Progress | 25% | text styles, button styles, background brush, owner-drawn button paint | Primary/secondary buttons now differ visually. Needs color tokens, hover state, disabled state, focus rings, theme switching, and modern surfaces. |
| 8: SwiftUI State And Invalidation | Not Started | 0% | `@State`, `Binding`, observable models, event invalidation, diff or rerender path | Required before apps can update UI without rebuilding windows manually. Compatibility with SwiftUI state concepts is a primary goal. |
| 9: Testing And Verification | Blocked / Partial | 10% | unit tests, console snapshots, renderer tests, UI smoke tests | Test sources exist, but local ARM64 Windows Swift/XCTest currently hits a UCRT overlay issue. `swift build` is the reliable verification path. |
| 10: Documentation And Examples | In Progress | 45% | GitHub README, architecture notes, examples, API docs | README is in good shape. Needs API reference, design docs, screenshots, and sample apps. |
| 11: Phase II Traditional Swift Framework | Planned | 0% | imperative windows, controls, events, layout, app lifecycle | A parallel non-declarative API may be easier to build simultaneously if the declarative SwiftUI-compatible layer wraps it. |
| 12: WebView And WebAssembly | Planned | 0% | WebView2 host control, navigation API, JS bridge, WebAssembly support | Windows equivalent should be Microsoft Edge WebView2, not WebKit. Needs Swift/COM interop design. |
| 13: Future Rendering Backends | Planned | 5% | Direct2D backend, WinUI backend exploration | Renderer boundary is ready, but only console and Win32 are present. |

## Milestones

### Milestone 1: Native Prototype

Status: Implemented

- Build a SwiftPM package.
- Create a native Windows window.
- Render basic text and buttons.
- Wire button actions through Win32 messages.
- Provide a console renderer for diagnostics.

### Milestone 2: Usable Mini Framework

Status: In Progress

- Add a real layout tree with measurement and placement.
- Add SwiftUI-compatible state primitives and rerender invalidation.
- Add core form controls: `TextField`, `Toggle`, `Picker`, and `Slider`.
- Add a WebView control backed by Microsoft Edge WebView2 with WebAssembly-capable content.
- Add common SwiftUI modifiers: `.padding`, `.frame`, `.font`, `.foregroundStyle`, `.background`, and `.disabled`.
- Add disabled, hover, focused, and pressed states for controls.
- Stabilize native resource ownership for fonts, brushes, pens, and window handles.

### Milestone 3: App-Quality Windows UI

Status: Planned

- Add custom panels, cards, separators, toolbars, and menus.
- Add a modern theme layer with semantic colors and typography.
- Add accessibility labels and keyboard traversal.
- Add DPI-aware layout and font scaling.
- Add sample apps that demonstrate realistic desktop workflows.

### Milestone 4: Framework Boundary And Embedding

Status: Planned

- Document the renderer protocol as an embeddable backend boundary.
- Split native Win32 declarations into a cleaner internal platform layer.
- Add integration guidance for other SwiftPM apps.
- Explore a Direct2D renderer for modern custom UI.
- Explore a WinUI renderer if the Windows App SDK path becomes practical from Swift.

### Milestone 5: SwiftUI Compatibility Push

Status: Planned

- Create a SwiftUI compatibility matrix.
- Build small examples that compile against both SwiftUI and SwiftWinUI where possible.
- Match common view initializers, modifier names, and result-builder behavior.
- Add `@State`, `Binding`, `Environment`, and environment-driven modifiers.
- Document unsupported or intentionally different SwiftUI APIs.

### Milestone 6: Phase II Traditional Framework

Status: Planned

- Define a traditional Swift API for windows, controls, layout containers, and events.
- Decide package/product naming for the imperative framework, such as `SwiftWin` or `SwiftWinCore`.
- Make the imperative layer usable directly for developers who do not want declarative UI.
- Evaluate whether Phase I should wrap Phase II internally so both frameworks evolve together.
- Keep shared renderer/runtime/platform code in one place to avoid divergent behavior.

## Phase Details

## Phase I: SwiftUI-Compatible Declarative Framework

Phase I is the current `SwiftWinUI` direction: a SwiftUI-compatible declarative API for Windows. Its goal is maximum practical source and concept compatibility with SwiftUI.

If Phase II proves to be the cleaner internal architecture, Phase I should wrap Phase II primitives rather than duplicating window, control, event, and layout machinery.

### 1: Repository And Package Structure

Status: Implemented

Implemented:

- SwiftPM package at `Code/SwiftWinUI`.
- Library product named `SwiftWinUI`.
- Executable product named `SwiftWinUIDemo`.
- Test target placeholder.
- GitHub-style README.
- Windows linker settings for `user32`, `kernel32`, `gdi32`, and `uxtheme`.

Remaining:

- Add CI once the toolchain path and Windows runner are known.
- Add license file.
- Add package metadata and contribution notes.

### 2: SwiftUI-Compatible API Foundation

Status: Implemented / Expanding

Implemented:

- `App`
- `Scene`
- `WindowGroup`
- `View`
- `ViewBuilder`
- `AnyView`
- `TupleView`

Remaining:

- Add `ForEach`.
- Add `Group`.
- Add `ViewModifier`.
- Add conditional view support beyond simple optional/either branches.
- Add modifiers such as `.padding`, `.frame`, `.foregroundStyle`, `.font`, `.disabled`, and `.accessibilityLabel`.
- Add environment values and environment propagation.
- Audit public names against SwiftUI before introducing custom names.
- Decide whether modifiers become wrapper views, environment values, or normalized render nodes.

### 3: Renderer Boundary

Status: Implemented / Expanding

Implemented:

- `Renderer` protocol.
- `ConsoleRenderer`.
- `Win32Renderer`.
- Default renderer selection uses `Win32Renderer` on Windows and `ConsoleRenderer` elsewhere.

Remaining:

- Move from immediate rendering calls to a normalized render tree.
- Add renderer lifecycle hooks.
- Add reusable resource caches for fonts, brushes, pens, and native controls.
- Define renderer error behavior.

### 4: Native Win32 Runtime

Status: In Progress

Implemented:

- Window class registration.
- Native window creation.
- Message loop.
- `WM_COMMAND` routing for buttons.
- `WM_DRAWITEM` owner-draw support for buttons.
- `WM_CTLCOLORSTATIC` text background and color handling.

Remaining:

- Multiple windows.
- Modal window ownership.
- Window resize handling.
- DPI awareness.
- Keyboard traversal.
- Window lifecycle callbacks.
- Clean teardown for cached GDI resources.

### 5: SwiftUI Control Coverage

Status: In Progress

Implemented:

- `Text`
- `Button`
- `Spacer`
- `VStack`
- `HStack`
- `Dialog.show`

Remaining:

- `TextField`
- `SecureField`
- `Toggle`
- `Picker`
- `Slider`
- `Image`
- `List`
- `ScrollView`
- `Divider`
- `Panel`
- `Toolbar`
- `Menu`
- `WebView`
- SwiftUI-compatible initializer overloads for implemented controls.

### 5A: WebView And WebAssembly

Status: Planned

Windows does not have a direct Apple WebKit equivalent in the same sense as macOS `WKWebView`. The practical Windows-native answer is Microsoft Edge WebView2, which embeds the Chromium-based Microsoft Edge runtime in desktop apps. WebView2 should be the default web view backend for SwiftWinUI.

Planned:

- Add a SwiftUI-compatible `WebView` wrapper.
- Add a Phase II imperative `WinWebView` control.
- Host WebView2 as a native child control inside a SwiftWinUI window.
- Support navigation by URL and by local HTML string/file.
- Support WebAssembly content through the WebView2/Edge runtime.
- Add a JavaScript bridge for messages between Swift and web content.
- Add lifecycle hooks for navigation start, navigation complete, load errors, and document title changes.
- Decide how to distribute or detect the WebView2 Runtime: Evergreen Runtime for normal apps, Fixed Version Runtime for strict reproducibility.
- Document security defaults for local files, script injection, host object exposure, and WebAssembly execution.
- Investigate Swift COM interop options for `ICoreWebView2*` interfaces.

Open questions:

- Should WebView2 bindings be generated from WebView2 headers/IDL, hand-declared minimally, or isolated in a C/C++ shim target?
- Should the WebView package be optional so apps that do not need web content avoid WebView2 dependencies?
- How should local asset serving work for Monaco/editor-style apps: file URLs, virtual host mapping, or an embedded local server?
- Should WebAssembly examples be part of the demo app or a separate sample?

### 6: Layout Engine

Status: In Progress

Implemented:

- Basic stack placement.
- Horizontal and vertical advancement.
- Spacing support.

Remaining:

- Separate measure and place passes.
- Intrinsic sizes.
- Alignment.
- Padding.
- Fixed and flexible frames.
- SwiftUI-like layout priorities where practical.
- Minimum and maximum sizes.
- DPI scaling.
- Resize invalidation.
- Scrollable regions.

### 7: Styling And Theming

Status: In Progress

Implemented:

- `TextStyle`
- `FontWeight`
- `ButtonStyle`
- Segoe UI font creation.
- Light background brush.
- Owner-drawn primary and secondary buttons.

Remaining:

- Theme object with semantic colors.
- Disabled, hover, active, focused, and default states.
- Modern panel/surface styling.
- App-wide typography scale.
- Dark mode.
- High contrast mode.
- Theme documentation.

### 8: State And Invalidation

Status: Not Started

Planned:

- Add a SwiftUI-compatible `@State` primitive or equivalent property wrapper.
- Add `Binding`.
- Add environment and environment object equivalents.
- Add event-driven invalidation.
- Reconcile view updates without rebuilding the full native window every time.
- Decide whether the renderer owns native control identity or receives stable view IDs.
- Add sample stateful controls.

## SwiftUI Compatibility Principles

1. Prefer SwiftUI names over new names.
2. Prefer SwiftUI initializer shapes and default arguments where possible.
3. Prefer modifiers over one-off control-specific configuration.
4. Keep Windows-specific details internal to renderers unless the user explicitly opts into them.
5. When exact behavior is impossible, document the gap and keep the public API as close as possible.
6. Build compatibility examples that can be compared against equivalent SwiftUI snippets.
7. Avoid adding abstractions that would make future SwiftUI compatibility harder.

## SwiftUI Compatibility Targets

| Area | Target | Current Status |
| --- | --- | --- |
| App lifecycle | `App`, `Scene`, `WindowGroup` | Partial |
| View building | `View`, `@ViewBuilder`, tuple/conditional views | Partial |
| State | `@State`, `Binding`, observable models | Not started |
| Environment | `Environment`, environment values, environment-driven styling | Not started |
| Layout | `VStack`, `HStack`, `ZStack`, `Spacer`, frames, padding, alignment | Partial |
| Controls | `Text`, `Button`, `TextField`, `Toggle`, `Picker`, `Slider`, `List` | Partial |
| Modifiers | `.font`, `.foregroundStyle`, `.background`, `.padding`, `.frame`, `.disabled` | Not started |
| Styling | SwiftUI-like semantic styles with Windows rendering | Partial |
| Accessibility | SwiftUI-like accessibility modifiers | Not started |
| Preview/testing | Console snapshots and examples instead of Xcode previews | Partial alternative |

### 9: Testing And Verification

Status: Blocked / Partial

Implemented:

- Test target exists.
- `swift build` validates framework and demo compilation.

Blocked:

- Local ARM64 Windows Swift snapshot may fail while importing XCTest because of a UCRT overlay module issue.

Planned:

- Console renderer snapshot tests.
- Layout engine tests.
- Button action routing tests.
- Native smoke test that launches and closes a window.
- Screenshot-based UI checks once a reliable runner is available.

### 10: Documentation And Examples

Status: In Progress

Implemented:

- README with overview, quick start, example, architecture, limitations, and roadmap.
- Framework design document in `Documents`.

Remaining:

- Add screenshots.
- Add API reference.
- Add a small gallery app.
- Add Windows-for-Apple-developers notes whenever a Windows concept differs from AppKit, UIKit, SwiftUI, or `WKWebView` expectations.
- Add notes explaining why the current backend hand-declares Win32 APIs.
- Add embedding guide for other SwiftPM apps.

## Windows Notes For Apple Developers

SwiftWinUI documentation should call out Windows oddities explicitly, especially for developers coming from macOS, iOS, AppKit, UIKit, SwiftUI, or `WKWebView`.

Concepts to explain as they appear:

- `HWND` as both window and control handle.
- Message loops and `WM_*` event dispatch.
- Child windows versus view hierarchies.
- GDI objects: `HDC`, `HBRUSH`, `HPEN`, `HFONT`, and resource cleanup.
- COM interfaces and reference-counted native APIs.
- DLL/link library names such as `user32`, `gdi32`, `kernel32`, `uxtheme`, and future WebView2 libraries.
- DPI awareness and coordinate scaling.
- WebView2 versus `WKWebView`, including Evergreen versus Fixed Version runtime distribution.
- High contrast, accessibility, keyboard traversal, and focus behavior.
- PowerShell, Developer Command Prompt, PATH, and Swift toolchain discovery.

## Phase II: Traditional Non-Declarative Swift Framework

Status: Planned

Phase II adds a parallel traditional Swift interface for Windows UI. This layer is not declarative and does not attempt to look like SwiftUI. It should feel like a clean Swift wrapper over native Windows app concepts: application, windows, controls, containers, events, commands, layout, resources, and dialogs.

This may be implemented after Phase I reaches a stable prototype, or simultaneously if it makes Phase I easier. In particular, if the declarative layer becomes simpler as a wrapper around imperative objects, Phase II should be started during Phase I and treated as the shared runtime/control foundation.

### Phase II Goals

- Provide a direct imperative API for developers who prefer traditional UI programming.
- Offer explicit control over windows, controls, events, and lifecycle.
- Serve as a possible underlying engine for the SwiftUI-compatible declarative layer.
- Keep native Win32 details hidden behind Swift types.
- Share renderer/runtime/platform code with Phase I.

### Candidate API Shape

```swift
let app = WinApplication()

let window = WinWindow(title: "SwiftWin Demo", width: 960, height: 640)
let stack = WinStack(axis: .vertical, spacing: 14)

stack.add(WinText("SwiftWin", style: .title))
stack.add(WinButton("Create Window", style: .primary) {
    WinDialog.show(title: "Create Window", message: "Traditional button action.")
})

window.content = stack
app.run(window)
```

### Phase II Dashboard

| Area | Status | Progress | Planned Work | Notes |
| --- | --- | ---: | --- | --- |
| Package/Product Shape | Planned | 0% | choose module name, package product, folder layout | Likely separate product beside `SwiftWinUI`. |
| Application Runtime | Planned | 0% | `WinApplication`, message loop, lifecycle callbacks | Can share code with current `ApplicationRuntime` and `Win32Renderer`. |
| Window API | Planned | 0% | `WinWindow`, size, title, show/close, events | Should become the primitive that declarative `WindowGroup` can target. |
| Controls | Planned | 0% | `WinText`, `WinButton`, `WinTextField`, `WinToggle`, `WinList` | These can map directly to native HWNDs or custom-drawn controls. |
| Layout Containers | Planned | 0% | `WinStack`, `WinGrid`, `WinScrollView`, sizing primitives | Could provide the layout engine used by Phase I. |
| Events And Commands | Planned | 0% | closures, command IDs, keyboard shortcuts, menu actions | Should be explicit and testable. |
| Styling | Planned | 0% | control styles, theme tokens, fonts, colors | Shared styling engine can feed both Phase I and Phase II. |
| Interop Boundary | Planned | 0% | expose native handles safely when needed | Advanced users may need controlled access to HWND/HDC. |

### Phase II Design Principles

1. Be traditional and explicit, not declarative.
2. Use Swift naming and value types where they make the API safer.
3. Keep native handles private by default, with deliberate escape hatches.
4. Prefer one shared native implementation beneath both Phase I and Phase II.
5. Avoid adding Phase II concepts that make SwiftUI compatibility harder for Phase I.
6. Treat Phase II as the possible substrate for Phase I if it reduces duplication.

### Phase II Open Questions

- Should the module be named `SwiftWin`, `SwiftWinCore`, or `SwiftWinControls`?
- Should Phase I depend on Phase II publicly or only internally?
- Should the imperative API expose actual control objects, lightweight descriptors, or both?
- Should layout live in Phase II first, then be wrapped by Phase I?
- How much direct HWND access should advanced users get?

## Unsupported SwiftWinUI Coverage

| Area | Current Support | Gap |
| --- | --- | --- |
| Text | Basic static text | No wrapping, selection, rich text, dynamic color, or accessibility metadata |
| Buttons | Owner-drawn primary/secondary buttons with click actions | No hover tracking, disabled state, icons, keyboard default action, or command abstraction |
| Layout | Basic stack positioning | No full measurement, alignment, padding, flexible sizing, resize handling, or scroll layout |
| State | None | No `@State`, bindings, observable models, or invalidation |
| Forms | None | No text fields, toggles, pickers, sliders, or validation |
| WebView | None | No WebView2 hosting, navigation API, JavaScript bridge, local asset loading, or WebAssembly sample |
| Lists | None | No table/list view, diffing, selection, or virtualization |
| Images | None | No bitmap loading, scaling, or icon rendering |
| Menus | None | No menu bar, context menus, toolbar commands, or accelerators |
| Accessibility | None | No labels, roles, focus traversal, or assistive technology metadata |
| Theming | Partial | No dark mode, high contrast, semantic token system, hover/pressed/disabled palette, or user themes |
| Testing | Partial / blocked | Build works; XCTest currently blocked on this local ARM64 Windows snapshot |

## Near-Term Backlog

1. Add hover tracking for owner-drawn buttons.
2. Add disabled button support.
3. Decide whether to start Phase II now as the imperative foundation for Phase I.
4. Choose a Phase II module/product name.
5. Introduce `Padding` and `Frame` modifiers.
6. Extract Win32 handle declarations into a private platform file.
7. Add a simple layout node tree.
8. Add `TextField`.
9. Prototype `WebView` / `WinWebView` with WebView2.
10. Add a WebAssembly sample page loaded inside WebView2.
11. Add a tiny state primitive and rerender sample.
12. Add console snapshot verification.
13. Add screenshots to the README.
14. Choose and add a license.
