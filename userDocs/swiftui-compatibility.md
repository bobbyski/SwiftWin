# SwiftUI Compatibility Goal

SwiftWinUI aims for maximum practical SwiftUI compatibility.

Full compatibility may not be achievable on Windows, but compatibility is the design target. Public API decisions should prefer SwiftUI naming, modifier shape, result-builder behavior, state concepts, layout semantics, and view composition patterns wherever practical.

## Compatibility Priorities

1. Source compatibility for common SwiftUI app structure and view declarations.
2. Matching control and layout names where behavior can be made close enough.
3. Matching modifier names and chaining style.
4. Matching state and binding concepts.
5. Matching behavior where Windows can support it cleanly.
6. Documented compatibility gaps where Windows, SwiftPM, or the backend requires different behavior.

## Current Compatibility

| SwiftUI Area | SwiftWinUI Status |
| --- | --- |
| `App` | Partial |
| `Scene` | Partial |
| `WindowGroup` | Partial |
| `View` | Partial |
| `@ViewBuilder` | Partial |
| `Text` | Partial |
| `Button` | Partial |
| `VStack` / `HStack` | Partial |
| `Spacer` | Partial |
| `@State` | Partial |
| `Binding` | Partial |
| `Environment` | Not implemented |
| Modifiers | Partial: `.padding`, `.frame(width:height:)`, `.disabled(_:)`, `.font(_:)` |
| `TextField` | Partial |
| `Toggle` | Partial |
| `List` | Not implemented |
| `Image` | Not implemented |
| `WebView` | Planned |

## State And Invalidation

`State` and `Binding` now exist and can be used by the first form controls.

```swift
@State private var projectName = "SwiftWin"
@State private var scale = 50

TextField("Project name", text: $projectName)
Slider("Scale", value: $scale, range: 0...100)
```

State writes also notify a renderer invalidation hook. The current Win32
renderer uses that hook to refresh dynamic `Text` values, so simple dependent
labels can update after state changes.

```swift
@State private var scale = 50

Slider("Scale", value: $scale, range: 0...100)
Text("Live scale preview: \(scale)", style: .caption)
```

Full native reconciliation is still planned. Layout changes, conditional view
changes, and arbitrary control replacement still need the future rebuild/diff
pass.

## Layout Modifiers

SwiftWinUI now includes early compatibility forms for `.padding(_:)` and
`.frame(width:height:)`.

```swift
TextField("Project name", text: $projectName)
    .frame(width: 340)

VStack(spacing: 14) {
    Text("SwiftWinUI")
}
.padding(12)
```

The current `.frame(width:height:)` implementation is intentionally narrow: it
acts as a fixed-size native layout proposal. SwiftUI's richer frame overloads,
alignment behavior, ideal sizes, and min/max constraints are still planned.

## Disabled State

`.disabled(_:)` exists for interactive controls.

```swift
Button("Disabled") {}
    .disabled()
```

The current Windows backend applies native HWND disabled state with
`EnableWindow` and gives owner-drawn controls disabled colors. Dynamic disabled
conditions that depend on changing state will need the future native
reconciliation pass before they can fully match SwiftUI.

## Font Modifier

`.font(_:)` exists as an inherited text-style modifier.

```swift
VStack(spacing: 8) {
    Text("SwiftWinUI")
    Text("Native Windows, Swift-shaped.")
}
.font(.title)
```

This currently maps to SwiftWinUI's semantic `TextStyle` values. Explicit
`Text(..., style:)` values override the inherited modifier. Custom font
families, design variants, dynamic type, and weight composition are still
planned compatibility work.

## Hover State

Owner-drawn Win32 controls now react to explicit child-window hover tracking
and native hot-tracking paint state when Windows includes `ODS_HOTLIGHT` in
`DRAWITEMSTRUCT.itemState`.

This is not yet a SwiftUI `.onHover` API. A full hover API will require
public Swift closure hooks so app code can receive enter/exit events.

## Design Rules

- Prefer SwiftUI names over new names.
- Prefer SwiftUI initializer shapes and default arguments where possible.
- Prefer modifiers over one-off control-specific configuration.
- Keep Windows-specific details internal to renderers unless the user opts into them.
- When exact behavior is impossible, document the gap and keep the public API as close as possible.
- Avoid abstractions that would make future SwiftUI compatibility harder.

## Phase II Relationship

The project may add a traditional imperative Swift framework in parallel. If that layer makes implementation cleaner, the SwiftUI-compatible layer can wrap it internally while preserving SwiftUI-like public APIs.
