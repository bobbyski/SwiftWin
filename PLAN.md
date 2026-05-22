# SwiftWinUI Framework Implementation Plan

## Summary

This plan covers the work needed to grow the current experimental SwiftWinUI package from a focused SwiftPM prototype into a broader SwiftUI-compatible Windows UI framework with a declarative public API, native Windows rendering, richer controls, state-driven updates, better layout, documentation, and test coverage.

The strategic goal is maximum practical SwiftUI compatibility. SwiftWinUI should strive for source-level compatibility with common SwiftUI app code, even though 100% compatibility may not be achievable on Windows. Public API decisions should prefer SwiftUI naming, modifier shape, result-builder behavior, state concepts, layout semantics, and view composition patterns wherever practical. Platform-specific differences should be pushed behind renderer internals or documented as explicit compatibility gaps.

Overall planned-code progress: [###-------] 30%

The implemented base already includes the SwiftPM framework, demo executable, `App` and `WindowGroup` entry point, declarative `View` protocol, `ViewBuilder`, `Text`, `Button`, `Spacer`, `VStack`, `HStack`, text styles, button styles, a renderer protocol boundary, a diagnostic console renderer, a native Win32 renderer, real HWND window creation, native text controls, owner-drawn buttons, button command routing, native message boxes through `Dialog.show`, basic stack positioning, Windows linker settings, and a GitHub-style README. The next architectural steps are to separate layout measurement from rendering, add SwiftUI-compatible state and invalidation, expand the SwiftUI control and modifier catalog in tested batches, make renderer resources safer and more reusable, and document the framework boundary clearly enough for other apps to embed SwiftWinUI.

Unsupported and partially supported UI capabilities are tracked in [Unsupported SwiftWinUI Coverage](#unsupported-swiftwinui-coverage).

## Project Dashboard

| Phase | Status | Progress | Planned Work | Notes |
| --- | --- | ---: | --- | --- |
| 1: Repository And Package Structure | Implemented | 100% | `Code/SwiftWinUI`, SwiftPM library, demo target, tests folder, README, plan | Package structure exists and builds as a framework plus executable demo. |
| 2: SwiftUI-Compatible API Foundation | Implemented | 60% | `App`, `Scene`, `WindowGroup`, `View`, `ViewBuilder`, `AnyView`, tuple rendering | Core API shape resembles SwiftUI. Needs source-compatibility audit, modifiers, `ForEach`, `Group`, environment, and more result-builder forms. |
| 3: Renderer Boundary | Implemented | 80% | `Renderer` protocol, console renderer, native renderer selection | Public API is separated from backend rendering. Needs a richer render tree and resource lifecycle management. |
| 4: Native Win32 Window Runtime | Implemented | 65% | HWND creation, window class registration, message loop, command routing | Demo opens a native window and buttons work. Needs multiple windows, lifecycle events, errors, and graceful shutdown paths. |
| 5: SwiftUI Control Coverage | In Progress | 20% | `Text`, `Button`, `Spacer`, `Dialog` | Buttons are owner-drawn and dialogs work. Most SwiftUI views and controls are not implemented yet. |
| 6: Layout Engine | In Progress | 20% | stack positioning, spacing, basic child advancement | Current layout is direct placement. Needs measure/place passes, alignment, min/max sizes, wrapping, clipping, and DPI support. |
| 7: Styling And Theming | In Progress | 25% | text styles, button styles, background brush, owner-drawn button paint | Primary/secondary buttons now differ visually. Needs color tokens, hover state, disabled state, focus rings, theme switching, and modern surfaces. |
| 8: SwiftUI State And Invalidation | Not Started | 0% | `@State`, `Binding`, observable models, event invalidation, diff or rerender path | Required before apps can update UI without rebuilding windows manually. Compatibility with SwiftUI state concepts is a primary goal. |
| 9: Testing And Verification | Blocked / Partial | 10% | unit tests, console snapshots, renderer tests, UI smoke tests | Test sources exist, but local ARM64 Windows Swift/XCTest currently hits a UCRT overlay issue. `swift build` is the reliable verification path. |
| 10: Documentation And Examples | In Progress | 45% | GitHub README, architecture notes, examples, API docs | README is in good shape. Needs API reference, design docs, screenshots, and sample apps. |
| 11: Future Rendering Backends | Planned | 5% | Direct2D backend, WinUI backend exploration | Renderer boundary is ready, but only console and Win32 are present. |

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

## Phase Details

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
- SwiftUI-compatible initializer overloads for implemented controls.

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
- Add notes explaining why the current backend hand-declares Win32 APIs.
- Add embedding guide for other SwiftPM apps.

## Unsupported SwiftWinUI Coverage

| Area | Current Support | Gap |
| --- | --- | --- |
| Text | Basic static text | No wrapping, selection, rich text, dynamic color, or accessibility metadata |
| Buttons | Owner-drawn primary/secondary buttons with click actions | No hover tracking, disabled state, icons, keyboard default action, or command abstraction |
| Layout | Basic stack positioning | No full measurement, alignment, padding, flexible sizing, resize handling, or scroll layout |
| State | None | No `@State`, bindings, observable models, or invalidation |
| Forms | None | No text fields, toggles, pickers, sliders, or validation |
| Lists | None | No table/list view, diffing, selection, or virtualization |
| Images | None | No bitmap loading, scaling, or icon rendering |
| Menus | None | No menu bar, context menus, toolbar commands, or accelerators |
| Accessibility | None | No labels, roles, focus traversal, or assistive technology metadata |
| Theming | Partial | No dark mode, high contrast, semantic token system, hover/pressed/disabled palette, or user themes |
| Testing | Partial / blocked | Build works; XCTest currently blocked on this local ARM64 Windows snapshot |

## Near-Term Backlog

1. Add hover tracking for owner-drawn buttons.
2. Add disabled button support.
3. Introduce `Padding` and `Frame` modifiers.
4. Extract Win32 handle declarations into a private platform file.
5. Add a simple layout node tree.
6. Add `TextField`.
7. Add a tiny state primitive and rerender sample.
8. Add console snapshot verification.
9. Add screenshots to the README.
10. Choose and add a license.
