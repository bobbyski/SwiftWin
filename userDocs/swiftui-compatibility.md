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
| Modifiers | Not implemented |
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

## Design Rules

- Prefer SwiftUI names over new names.
- Prefer SwiftUI initializer shapes and default arguments where possible.
- Prefer modifiers over one-off control-specific configuration.
- Keep Windows-specific details internal to renderers unless the user opts into them.
- When exact behavior is impossible, document the gap and keep the public API as close as possible.
- Avoid abstractions that would make future SwiftUI compatibility harder.

## Phase II Relationship

The project may add a traditional imperative Swift framework in parallel. If that layer makes implementation cleaner, the SwiftUI-compatible layer can wrap it internally while preserving SwiftUI-like public APIs.
