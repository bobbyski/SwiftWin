# SwiftWinUI Framework Implementation Plan

## Working On Milestone 2: Usable Mini Framework

Milestone ladder progress: [##-----] 2 of 7 milestones active

Current milestone progress: [#########-] 88%

## Summary

This plan covers the work needed to grow the current experimental SwiftWinUI package from a focused SwiftPM prototype into a broader Windows UI family with two public layers: Phase I, a SwiftUI-compatible declarative framework, and Phase II, a traditional non-declarative Swift framework that can be used directly or serve as the imperative engine underneath the declarative layer.

The strategic goal is maximum practical SwiftUI compatibility. SwiftWinUI should strive for source-level compatibility with common SwiftUI app code, even though 100% compatibility may not be achievable on Windows. Public API decisions should prefer SwiftUI naming, modifier shape, result-builder behavior, state concepts, layout semantics, and view composition patterns wherever practical. Platform-specific differences should be pushed behind renderer internals or documented as explicit compatibility gaps.

Product rule: goal one is that Swift code written with Apple-platform instincts should feel like it works on Windows without constant platform trivia. Goal two is that controls should be polished by default. When Win32 has low-level behavior such as clipped static text, manual scrolling, or owner-draw state gaps, the SDK should capture that knowledge in shared backend metrics, controls, or layout primitives rather than forcing each app or demo to patch around it.

The core engineering style is small-function, protocol-oriented Swift. Public behavior should be captured in focused protocols wherever that improves type safety, interoperability, testability, or future custom implementations. Concrete classes should be default implementations of those contracts, and large implementation areas should be split before they become difficult to reason about.

Overall planned-code progress: [####------] 45%

The implemented base already includes the SwiftPM framework, demo executable, `App` and `WindowGroup` entry point, declarative `View` protocol, `ViewBuilder`, `Text`, `Button`, `Spacer`, `VStack`, `HStack`, text styles, inherited font and foreground style modifiers, button styles, a renderer protocol boundary, a diagnostic console renderer, a native Win32 renderer, real HWND window creation, native text controls, owner-drawn buttons, button command routing, native message boxes through `Dialog.show`, basic stack positioning, Windows linker settings, protocol extension points in `SwiftWinLegacy`, and GitHub-style README documentation. The next architectural steps are to separate layout measurement from rendering, add SwiftUI-compatible state and invalidation, expand the SwiftUI control and modifier catalog in tested batches, make renderer resources safer and more reusable, and split the traditional runtime into smaller protocol-backed components.

Unsupported and partially supported UI capabilities are tracked in [Unsupported SwiftWinUI Coverage](#unsupported-swiftwinui-coverage).

## Project Dashboard

| Phase | Status | Progress | Planned Work | Notes |
| --- | --- | ---: | --- | --- |
| 1: Repository And Package Structure | Implemented | 100% | `Code/SwiftWinUI`, SwiftPM library, demo target, tests folder, README, plan | Package structure exists and builds as a framework plus executable demo. |
| 2: SwiftUI-Compatible API Foundation | Implemented | 60% | `App`, `Scene`, `WindowGroup`, `View`, `ViewBuilder`, `AnyView`, tuple rendering | Core API shape resembles SwiftUI. Needs source-compatibility audit, modifiers, `ForEach`, `Group`, environment, and more result-builder forms. |
| 3: Renderer Boundary | Implemented | 80% | `Renderer` protocol, console renderer, native renderer selection | Public API is separated from backend rendering. Needs a richer render tree and resource lifecycle management. |
| 4: Native Win32 Window Runtime | Implemented | 67% | HWND creation, window class registration, message loop, command routing | Demo opens a native window and buttons work. Enter routes to the default primary command and Escape routes to explicit cancel commands. Needs multiple windows, lifecycle events, errors, and graceful shutdown paths. |
| 5: SwiftUI Control Coverage | In Progress | 72% | `Text`, `TextField`, `SecureField`, `TextEditor`, `Toggle`, `Picker`, `Slider`, `Stepper`, `ColorPicker`, `DatePicker`, `ProgressView`, `Button`, `Link`, `Divider`, `Spacer`, `Dialog`, `.onHover`, planned `WebView` | Core Milestone 2 form controls, masked secure input, multi-line text editing, integer stepping, dialog-backed color picking, date-only native picking, links, determinate progress, separators, hover callbacks, and provider-backed binding refresh exist. Most SwiftUI views and controls are not implemented yet. WebView2 should provide the Windows web view path. |
| 6: Layout Engine | In Progress | 27% | stack positioning, spacing, padding, fixed frame hints, basic child advancement, shared Win32 text metrics | Current layout is direct placement with early modifier containers and SDK-owned text sizing defaults. Needs measure/place passes, alignment, min/max sizes, wrapping, clipping, and DPI support. |
| 7: Styling And Theming | In Progress | 56% | text styles, `.font`, `.foregroundStyle`, `.background`, `.border`, `.cornerRadius`, button styles, background brush, owner-drawn button/toggle/picker paint, disabled and hover colors | Primary/secondary buttons, toggles, and picker options now have custom drawing, disabled colors, inherited text font and foreground styles, solid rounded background panels, rounded rectangular borders, and native hot-tracking hover paint. Needs broader color tokens, richer focus rings, true clipping, theme switching, and modern surfaces. |
| 8: SwiftUI State And Invalidation | In Progress | 60% | `@State`, `Binding`, event invalidation, dynamic text, provider-backed control refresh, imperative refresh API, planned observable models and reconciliation | `@State`, `Binding`, form control binding overloads, dynamic text refresh, inline validation refresh, progress refresh, provider-backed control refresh, direct `SwiftWinLegacy` control refresh, and batched imperative refresh exist. Full SwiftUI-compatible rerendering remains planned. |
| 9: Testing And Verification | Blocked / Partial | 10% | unit tests, console snapshots, renderer tests, UI smoke tests | Test sources exist, but local ARM64 Windows Swift/XCTest currently hits a UCRT overlay issue. `swift build` is the reliable verification path. |
| 10: Documentation And Examples | In Progress | 52% | GitHub README, architecture notes, examples, API docs | README and user docs cover current controls, state, disabled state, early layout modifiers, accessibility metadata hooks, and `.font`. Needs API reference, design docs, and sample apps. Documentation screenshots are deferred to the cleanup milestone. |
| 11: Phase II Traditional Swift Framework | In Progress | 29% | `SwiftWinLegacy`, imperative windows, controls, events, layout, app lifecycle | Simultaneous development is now the chosen approach. `SwiftWinUI` depends on and wraps `SwiftWinLegacy` for the current Win32 path. |
| 12: WebView And WebAssembly | Planned | 0% | WebView2 host control, navigation API, JS bridge, WebAssembly support | Windows equivalent should be Microsoft Edge WebView2, not WebKit. Needs Swift/COM interop design. |
| 13: Protocol-Oriented Architecture | In Progress | 35% | focused protocols, small functions, separable runtime/layout/platform pieces | `SwiftWinUI` controls and `SwiftWinLegacy` core/control/platform files are now split by responsibility. |
| 14: Future Rendering Backends | Planned | 5% | Direct2D backend, WinUI backend exploration | Renderer boundary is ready, but only console and Win32 are present. |
| 15: Demo Application Ladder | In Progress | 10% | increasingly complex demoable apps, real viability app | Current basic demos exist. The ladder below defines the proof path from smoke demos to a real application. |

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

Milestone 2 is not a single-control milestone. It is the first real framework
viability milestone: every added control also forces a piece of the shared
runtime to mature. A checkbox, for example, touches event routing, native state
sync, owner-draw painting, hover/disabled/focus handling, dynamic text refresh,
binding providers, imperative refresh, layout metrics, and documentation. The
workstreams below make that hidden substrate visible so progress is easier to
reason about.

#### Milestone 2 Workstreams

| Workstream | Status | Details |
| --- | --- | --- |
| Declarative API Surface | In Progress | Add SwiftUI-shaped controls, initializer overloads, result-builder compatibility, and modifier spelling while avoiding Windows-specific public API unless necessary. |
| Traditional API Surface | In Progress | Add matching `SwiftWinLegacy` controls first or alongside the declarative wrapper so Phase I can wrap Phase II instead of duplicating native behavior. |
| Control State Model | In Progress | Keep Swift values, native HWND values, callbacks, `Binding` providers, and imperative object mutation coherent without full view diffing yet. |
| Event Routing | In Progress | Route `WM_COMMAND`, trackbar notifications, owner-drawn button clicks, shell-link activation, and future control-specific notifications back into Swift closures. |
| Dynamic Invalidation | In Progress | Refresh dependent text/progress/control values after user interaction and after imperative reset actions without recreating the whole native window. |
| Owner-Draw Styling | In Progress | Paint controls that stock Win32 renders too dated or too inflexibly, including buttons, toggles, pickers, links, steppers, and color swatches. |
| Native Control Hosting | In Progress | Create, size, register, enable/disable, refresh, and repaint child HWND controls consistently across Legacy and declarative entry points. |
| Layout And Scrolling | Partial | Support stack placement, spacing, padding, fixed frames, text sizing defaults, and early wheel scrolling while preparing for real measure/place and `ScrollView`. |
| Windows Polish Defaults | In Progress | Hide Win32 oddities such as clipped labels, static-control paint backgrounds, trackbar brush quirks, and missing hover feedback behind SDK defaults. |
| Documentation And Comparison | In Progress | Keep README, user docs, comparison matrix, and plan aligned after every visible control or Windows-specific behavior change. |

#### Milestone 2 Control And Runtime Checklist

- [x] Add `TextField` / `WinTextField` with callback and binding support.
- [x] Add `SecureField` / `WinSecureField` for masked single-line text entry.
- [x] Add multi-line `TextEditor` / `WinTextEditor` for simple notes and document-like input.
- [x] Add `Toggle` / `WinToggle` with owner-drawn checkbox styling.
- [x] Add `Picker` / `WinPicker` with segmented selection styling.
- [x] Add `Slider` / `WinSlider` with live value refresh and trackbar paint fixes.
- [x] Add `Stepper` / `WinStepper` with compact and integrated-value variants.
- [x] Add determinate `ProgressView` / `WinProgressView` with provider-backed refresh.
- [x] Add `Link` / `WinLink` for external URL and protocol opening through Windows shell handlers.
- [x] Add `ColorPicker` / `WinColorPicker` with an owner-drawn swatch, native common color dialog, and binding/callback support.
- [x] Add date-only `DatePicker` / `WinDatePicker` with native Win32 Date Time Picker hosting and document the segmented keyboard-entry behavior.
- [x] Add common SwiftUI modifiers: `.padding`, `.frame`, `.font`, `.foregroundStyle`, `.background`, `.border`, `.cornerRadius`, and `.disabled`.
- [x] Add disabled, pressed, hover, and visible keyboard-focused paint states for owner-drawn controls.
- [x] Add native edit-control focus coloring so text fields are visible without relying only on the caret.
- [x] Add internal hover tracking for owner-drawn control paint.
- [x] Add imperative refresh for single controls and batched multi-control updates.
- [x] Add dynamic text and progress refresh after form events.
- [ ] Add layout-affecting reconciliation without recreating the whole native window.
- [x] Add public hover APIs such as a SwiftUI-compatible `.onHover`.
- [x] Add first-pass Tab traversal through `IsDialogMessageW`, `WS_EX_CONTROLPARENT`, and a multiline editor Tab escape.
- [x] Add first-pass default command behavior by routing Enter to the first primary button.
- [x] Add explicit cancel command behavior with `ButtonRole.cancel` / `WinButtonRole.cancel` and Escape routing.
- [ ] Add richer keyboard shortcuts.
- [x] Add accessibility metadata hooks for labels, roles, and values.
- [ ] Add real `ScrollView` / `WinScrollView` with clipping and scrollbars.
- [ ] Add WebView control backed by Microsoft Edge WebView2 with WebAssembly-capable content.
- [x] Add native dialog-backed color selection for `ColorPicker` / `WinColorPicker`.
- [ ] Add SwiftUI-compatible `Foundation.Date` overloads for `DatePicker` when the Windows toolchain allows Foundation safely.
- [ ] Stabilize native resource ownership for fonts, brushes, pens, and window handles.
- [ ] Add a modern segmented-control visual treatment for integrated controls such as `Stepper` so `- | value | +` feels like one cohesive control rather than separate Win32 boxes.

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

Status: In Progress

- Define a traditional Swift API for windows, controls, layout containers, and events.
- Use `SwiftWinLegacy` as the traditional package product name.
- Make the imperative layer usable directly for developers who do not want declarative UI.
- Wrap Phase II internally from Phase I so both frameworks evolve together.
- Keep shared renderer/runtime/platform code in one place to avoid divergent behavior.

### Milestone 7: Cleanup And Documentation Polish

Status: Planned

- Capture final screenshots for README and user documentation after the default UI polish is representative.
- Refresh README images after major visual styling changes settle.
- Audit user docs for stale implementation notes.
- Tighten examples, file links, and platform caveats before broader sharing.
- Confirm all demo screenshots show current SwiftWinLegacy and SwiftWinUI behavior.

## Demo Application Checklist

This checklist turns framework progress into increasingly complex applications that can be run, inspected, and used as viability tests. Each demo should exist in both forms when practical: a `SwiftWinLegacy` version that proves the imperative layer, and a `SwiftWinUI` version that proves the declarative wrapper.

### Milestone 1 Demo: Window Smoke Test

Goal: prove that Swift can create and run a native Windows desktop process with a visible UI.

- [x] Create a native top-level Win32 window.
- [x] Render static text.
- [x] Render clickable buttons.
- [x] Route button actions to Swift closures.
- [x] Show native message dialogs.
- [x] Provide both `SwiftWinUIDemo` and `SwiftWinLegacyDemo`.

Demoable app: a simple welcome window with two buttons and a status/caption line.

### Milestone 2 Demo: Form And State Demo

Goal: prove that basic desktop form workflows are viable.

- [x] Add `TextField` / `WinTextField`.
- [x] Add `SecureField` / `WinSecureField`.
- [x] Add `TextEditor` / `WinTextEditor`.
- [x] Add `Link` / `WinLink`.
- [x] Add `Toggle` / `WinToggle`.
- [x] Add `Picker` or segmented selection.
- [x] Add `Slider` or numeric entry.
- [x] Add `ColorPicker` / `WinColorPicker` dialog-backed swatch selection.
- [x] Add `DatePicker` / `WinDatePicker` first-pass date selection.
- [x] Add `@State` and `Binding`-style data flow in `SwiftWinUI`.
- [x] Add imperative value change callbacks in `SwiftWinLegacy`.
- [x] Validate input and show inline error text.
- [x] Update simple dependent text without recreating the whole native window.
- [x] Update arbitrary controls without recreating the whole native window.
- [x] Add imperative refresh for traditional controls after code-driven value changes.
- [x] Add batched imperative refresh for multi-control updates.
- [ ] Update layout-affecting view changes without recreating the whole native window.

Demoable app: a small settings editor with text fields, toggles, validation, save/cancel actions, and live preview text.

### Milestone 3 Demo: Layout And Navigation Gallery

Goal: prove that the framework can handle real app layout, resizing, and navigation patterns.

- [ ] Add measure/place layout passes.
- [x] Add initial padding and fixed frame modifiers.
- [ ] Add alignment, min/max size, and flexible spacer behavior.
- [ ] Add `ScrollView` / `WinScrollView`.
- [ ] Add `List` or table-like row rendering.
- [ ] Add toolbar or command strip controls.
- [ ] Handle window resizing without broken layout.
- [ ] Add keyboard traversal and focused control styling.
- [ ] Add high-DPI scaling checks.

Demoable app: a component gallery with sidebar navigation, resizable panes, scrollable content, and examples of every implemented control.

### Milestone 4 Demo: Document-Style Productivity App

Goal: prove that SwiftWinUI can support a normal desktop workflow with persistent data.

- [ ] Add menus or command routing for common actions.
- [ ] Add file open/save dialogs or equivalent native file integration.
- [ ] Add text editing beyond a single-line field.
- [ ] Add dirty-state tracking and close confirmation.
- [ ] Add keyboard shortcuts and command enable/disable state.
- [ ] Add local persistence for app settings.
- [ ] Add accessibility labels for primary controls.
- [ ] Add light/dark/high-contrast theme checks.

Demoable app: a small notes or markdown editor with a document list, editor pane, preview/status area, save/load behavior, and keyboard shortcuts.

### Milestone 5 Demo: WebView And WebAssembly Workbench

Goal: prove that modern embedded web content is viable on Windows.

- [ ] Add `WinWebView` backed by Microsoft Edge WebView2.
- [ ] Add SwiftUI-compatible `WebView`.
- [ ] Load remote URLs.
- [ ] Load local HTML assets.
- [ ] Run a WebAssembly sample in the embedded view.
- [ ] Add Swift-to-JavaScript and JavaScript-to-Swift messaging.
- [ ] Document WebView2 runtime detection and distribution.
- [ ] Document security defaults for local content, host objects, and script injection.

Demoable app: a WebView workbench with an address field, navigation controls, local sample selector, JavaScript bridge log, and WebAssembly demo page.

### Milestone 6 Demo: Real Viability Application

Goal: prove that SwiftWinUI and SwiftWinLegacy are credible foundations for real Windows application development.

- [ ] Combine forms, lists, navigation, persistence, commands, dialogs, WebView2, and custom styling in one app.
- [ ] Exercise both declarative and imperative APIs in meaningful places.
- [ ] Use protocol-backed custom controls to validate extensibility.
- [ ] Include a realistic multi-pane layout with resizing and scrolling.
- [ ] Include local project/document persistence.
- [ ] Include embedded web documentation or preview content through WebView2.
- [ ] Include background work with UI progress and cancellation.
- [ ] Include robust error presentation and recovery flows.
- [ ] Include keyboard shortcuts, focus behavior, and accessibility labels.
- [ ] Include smoke tests or snapshot checks for the main screens.
- [ ] Package build/run instructions so another developer can clone and evaluate the app.

Candidate real app: a Swift package workbench for Windows that can open a SwiftPM package, show package targets/files, edit notes or markdown documentation, run configured build commands, display logs, and show embedded WebView documentation/previews. This would test whether the framework can support a practical developer tool rather than only a UI toy.

### Milestone 7 Demo: Cleanup Documentation Pass

Goal: make the public project documentation match the implemented framework after the viability demos prove the platform direction.

- [ ] Capture clean screenshots of `SwiftWinUIDemo`.
- [ ] Capture clean screenshots of `SwiftWinLegacyDemo`.
- [ ] Add screenshots to README and user documentation.
- [ ] Verify screenshots show the current default polished controls.
- [ ] Remove or archive obsolete screenshots after major visual changes.
- [ ] Re-read docs as a first-time Windows Swift developer and fix confusing gaps.

Demoable output: a documentation-ready repository with current screenshots, tested build/run snippets, and user docs that reflect the actual SDK behavior.

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
- Add modifiers such as `.foregroundStyle`, `.font`, `.disabled`, and `.accessibilityLabel`.
- Expand `.padding` and `.frame(width:height:)` into fuller SwiftUI-compatible layout semantics.
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
- `Divider`
- `Dialog.show`
- `TextField`
- `SecureField`
- `TextEditor`
- `Toggle`
- `Picker`
- `Slider`
- `Stepper`
- `ProgressView`
- `Link`
- `ColorPicker`
- `DatePicker`

Remaining:

- `Image`
- `List`
- `ScrollView`
- `Panel`
- `Toolbar`
- `Menu`
- `WebView`
- Dialog-backed `ColorPicker`
- SwiftUI-compatible `Foundation.Date` overloads for `DatePicker`
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
- Uniform padding modifier.
- Fixed width/height frame proposal.
- Prototype window-level mouse-wheel scrolling by moving child `HWND` controls and forcing a full redraw.
- Shared text sizing defaults to avoid clipped labels and text entry descenders.
- Scroll invalidation fixes for owner-drawn controls and dynamic labels.

Remaining:

- Separate measure and place passes.
- Intrinsic sizes.
- Alignment.
- Min/max frame overloads and flexible sizing.
- SwiftUI-like layout priorities where practical.
- Minimum and maximum sizes.
- DPI scaling.
- Resize invalidation.
- Real `ScrollView` / `WinScrollView` with clipping, scrollbars, nested content, and targeted repainting.

### 7: Styling And Theming

Status: In Progress

Implemented:

- `TextStyle`
- `FontWeight`
- `ButtonStyle`
- Segoe UI font creation.
- Light background brush.
- Owner-drawn primary and secondary buttons.
- Owner-drawn toggle, picker, link, stepper, and color-picker surfaces.
- Transparent text labels by default, with explicit control-surface brushes where Win32 requires them.
- Basic disabled, pressed, focused, and hover paint states for owner-drawn controls.

Remaining:

- Theme object with semantic colors.
- Public active-state APIs.
- Default/cancel command styling.
- Segmented-control drawing for `Picker`, integrated `Stepper`, and future compact multi-action controls.
- Modern panel/surface styling.
- App-wide typography scale.
- Dark mode.
- High contrast mode.
- Theme documentation.

### 8: State And Invalidation

Status: In Progress

Implemented:

- SwiftUI-compatible `@State` primitive.
- Closure-backed `Binding`.
- Binding overloads for `TextField`, `SecureField`, `TextEditor`, `Toggle`, `Picker`, `Slider`, `Stepper`, `ColorPicker`, and `DatePicker`.
- Event-driven invalidation hook through `StateInvalidation` and `Renderer.invalidate()`.
- Dynamic `Text` refresh for simple state-dependent labels.
- Provider-backed native refresh for existing form controls.
- Imperative `SwiftWinLegacy` refresh APIs for direct object mutation.
- Batched control refresh for reset-style updates.

Remaining:

- Add environment and environment object equivalents.
- Reconcile view updates without rebuilding the full native window every time.
- Decide whether the renderer owns native control identity or receives stable view IDs.
- Handle layout-affecting state changes.

## SwiftUI Compatibility Principles

1. Prefer SwiftUI names over new names.
2. Prefer SwiftUI initializer shapes and default arguments where possible.
3. Prefer modifiers over one-off control-specific configuration.
4. Keep Windows-specific details internal to renderers unless the user explicitly opts into them.
5. When exact behavior is impossible, document the gap and keep the public API as close as possible.
6. Build compatibility examples that can be compared against equivalent SwiftUI snippets.
7. Avoid adding abstractions that would make future SwiftUI compatibility harder.

## Implementation Design Principles

1. Keep functions as small as reasonably practical.
2. Prefer focused protocols where they make contracts clearer or custom implementations easier.
3. Let concrete classes be default implementations behind protocol-shaped behavior.
4. Keep public APIs type-safe, with explicit escape hatches for advanced native interop.
5. Split platform declarations, layout, event routing, resource ownership, and rendering into separate components as they grow.
6. Avoid protocols that exist only for ceremony; each protocol should protect a useful extension point or boundary.
7. Favor shared protocol-backed primitives between `SwiftWinLegacy` and `SwiftWinUI` when that keeps behavior consistent.

## SwiftUI Compatibility Targets

| Area | Target | Current Status |
| --- | --- | --- |
| App lifecycle | `App`, `Scene`, `WindowGroup` | Partial |
| View building | `View`, `@ViewBuilder`, tuple/conditional views | Partial |
| State | `@State`, `Binding`, observable models | Partial: `@State`, `Binding`, control bindings, dynamic text refresh |
| Environment | `Environment`, environment values, environment-driven styling | Not started |
| Layout | `VStack`, `HStack`, `ZStack`, `Spacer`, frames, padding, alignment | Partial |
| Controls | `Text`, `Button`, `TextField`, `Toggle`, `Picker`, `Slider`, `Stepper`, `ColorPicker`, `DatePicker`, `ProgressView`, `Divider`, `List` | Partial: form controls exist with callbacks and `Binding` overloads; integer stepping maps to `WinStepper`; first-pass color picking maps to `WinColorPicker`; date-only picking maps to `WinDatePicker`; determinate progress maps to `WinProgressView`; `Divider` maps to `WinSeparator` |
| Modifiers | `.font`, `.foregroundStyle`, `.background`, `.border`, `.cornerRadius`, `.padding`, `.frame`, `.disabled` | Partial: `.padding`, `.frame(width:height:)`, `.disabled(_:)`, `.font(_:)`, `.foregroundStyle(_:)` for text, `.background(_:)` solid colors, `.border(_:width:)`, `.cornerRadius(_:)` for decorations |
| Styling | SwiftUI-like semantic styles with Windows rendering | Partial: owner-drawn controls include basic enabled, disabled, pressed, focused, and hover colors; text supports semantic foreground colors; containers support solid rounded background panels and rounded rectangular borders |
| Accessibility | SwiftUI-like accessibility modifiers | Partial: metadata containers and modifiers exist for labels, roles, values, and hints; Windows UI Automation exposure remains planned |
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

This is now being implemented simultaneously with Phase I. The declarative layer wraps imperative objects for the current Win32 path, making `SwiftWinLegacy` the shared runtime/control foundation.

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
| Package/Product Shape | Implemented | 100% | `SwiftWinLegacy` library product, `SwiftWinLegacyDemo` executable | Module name is chosen and wired into SwiftPM. |
| Application Runtime | In Progress | 35% | `WinApplication`, message loop, lifecycle callbacks | `WinApplication` can run one `WinWindow`; lifecycle callbacks remain planned. |
| Window API | In Progress | 30% | `WinWindow`, size, title, show/close, events | `WinWindow` supports title, size, and content. Events remain planned. |
| Protocol Contracts | In Progress | 25% | app runner, containers, text, titled/action controls, button contracts | Initial public protocols exist so custom controls and runtimes can interoperate. |
| Controls | In Progress | 60% | `WinText`, `WinButton`, `WinTextField`, `WinToggle`, `WinPicker`, `WinSlider`, `WinStepper`, `WinColorPicker`, `WinDatePicker`, `WinProgressView`, `WinSeparator`, `WinList` | `WinText`, form controls, integer stepping, palette-cycle color picking, date-only native picking, determinate progress, `WinButton`, `WinSeparator`, `WinSpacer`, and `WinDialog` exist. |
| Layout Containers | In Progress | 25% | `WinStack`, `WinPadding`, `WinFrame`, `WinGrid`, `WinScrollView`, sizing primitives | `WinStack`, `WinPadding`, and `WinFrame` conform to `WinContainer` and use direct placement. Real layout remains planned. |
| Events And Commands | In Progress | 20% | closures, command IDs, keyboard shortcuts, menu actions | Button closures route through Win32 command IDs. |
| Styling | In Progress | 36% | control styles, theme tokens, fonts, colors, segmented-control drawing | Text styles, semantic foreground colors, inherited declarative `.font`, inherited declarative `.foregroundStyle`, solid rounded `.background`, rounded `.border`, and button styles exist; full theme tokens and cohesive segmented controls remain planned. |
| Interop Boundary | Planned | 0% | expose native handles safely when needed | Advanced users may need controlled access to HWND/HDC. |

### Phase II Design Principles

1. Be traditional and explicit, not declarative.
2. Use Swift naming and value types where they make the API safer.
3. Keep native handles private by default, with deliberate escape hatches.
4. Prefer one shared native implementation beneath both Phase I and Phase II.
5. Avoid adding Phase II concepts that make SwiftUI compatibility harder for Phase I.
6. Treat Phase II as the possible substrate for Phase I if it reduces duplication.
7. Keep implementation functions small and split responsibilities early.
8. Use protocols for extension points that custom controls, alternate runtimes, and future renderers may need.

### Phase II Open Questions

- Should `SwiftWinLegacy` remain the final name, or eventually graduate to `SwiftWin` once stable?
- Should Phase I expose the Phase II dependency publicly or keep it mostly internal?
- Should the imperative API expose actual control objects, lightweight descriptors, or both?
- Should layout live in Phase II first, then be wrapped by Phase I?
- How much direct HWND access should advanced users get?

## Unsupported SwiftWinUI Coverage

| Area | Current Support | Gap |
| --- | --- | --- |
| Text | Basic static text | No wrapping, selection, rich text, or dynamic color reconciliation; accessibility metadata can now be attached through modifier scopes |
| Buttons | Owner-drawn primary/secondary buttons with click actions | No hover tracking, disabled state, icons, keyboard default action, or command abstraction |
| Layout | Basic stack positioning with padding and fixed frame hints | No full measurement, alignment, min/max frames, flexible sizing, resize handling, or scroll layout |
| State | Partial | `@State`, `Binding`, invalidation hook, and dynamic text refresh exist. No observable models, environment, or general native reconciliation yet |
| Forms | Partial | `TextField`, `Toggle`, `Picker`, `Slider`, first-pass `ColorPicker`, and date-only `DatePicker` exist with callback and binding changes. Inline validation works in the demo, but there is no reusable validation API yet |
| WebView | None | No WebView2 hosting, navigation API, JavaScript bridge, local asset loading, or WebAssembly sample |
| Lists | None | No table/list view, diffing, selection, or virtualization |
| Images | None | No bitmap loading, scaling, or icon rendering |
| Menus | None | No menu bar, context menus, toolbar commands, or accelerators |
| Accessibility | Metadata hooks only | Labels, roles, values, and hints can be attached and stored per control; no UI Automation provider yet |
| Theming | Partial | No dark mode, high contrast, semantic token system, or user themes; disabled and hover palettes are early and control-specific |
| Testing | Partial / blocked | Build works; XCTest currently blocked on this local ARM64 Windows snapshot |

## Near-Term Backlog

1. Extend `.onHover` beyond tracked child controls to arbitrary layout regions.
2. Continue splitting Win32 layout and native control hosting into smaller files as the backend grows.
3. Add a simple layout node tree.
4. Add native reconciliation for invalidated state-dependent views.
5. Prototype `WebView` / `WinWebView` with WebView2.
6. Add a WebAssembly sample page loaded inside WebView2.
7. Add console snapshot verification.
