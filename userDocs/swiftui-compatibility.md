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
| `ScrollView` | Partial: vertical wheel-scrolled viewport only |
| `Spacer` | Partial |
| `Divider` | Partial |
| `@State` | Partial |
| `Binding` | Partial |
| `Environment` | Not implemented |
| Modifiers | Partial: `.padding`, `.frame(width:height:)`, `.disabled(_:)`, `.font(_:)`, `.foregroundStyle(_:)` for text, `.background(_:)` solid colors, `.border(_:width:)`, `.cornerRadius(_:)` for decorations, `.onHover(perform:)`, and first-pass accessibility metadata modifiers |
| `TextField` | Partial |
| `SecureField` | Partial |
| `TextEditor` | Partial |
| `Link` | Partial |
| `Toggle` | Partial |
| `Picker` | Partial |
| `Slider` | Partial |
| `Stepper` | Partial: integer values only |
| `ColorPicker` | Partial: native dialog-backed RGB swatch picker |
| `DatePicker` | Partial: date-only `CalendarDate` picker only |
| `ProgressView` | Partial: determinate progress only |
| `List` | Not implemented |
| `Image` | Not implemented |
| `WebView` | Planned |

## State And Invalidation

`State` and `Binding` now exist and can be used by the first form controls.

```swift
@State private var projectName = "SwiftWin"
@State private var scale = 50

TextField("Project name", text: $projectName)
SecureField("Access code", text: $accessCode)
Slider("Scale", value: $scale, range: 0...100)
ColorPicker("Accent color", selection: $accentColor)
DatePicker("Launch date", selection: $launchDate)
Link("Open Swift.org", destination: "https://www.swift.org")
```

State writes also notify a renderer invalidation hook. The current Win32
renderer uses that hook to refresh dynamic `Text` values, so simple dependent
labels can update after state changes.

```swift
@State private var scale = 50
@State private var quantity = 2

Slider("Scale", value: $scale, range: 0...100)
Stepper("Quantity", value: $quantity, range: 0...10, variant: .integratedValue)
Text("Live scale preview: \(scale)", style: .caption)
ProgressView("Scale progress", value: scale, total: 100)
ColorPicker("Accent color", selection: $accentColor)
DatePicker("Launch date", selection: $launchDate)
```

`DatePicker` currently uses SwiftWinUI's `CalendarDate` value instead of
SwiftUI's `Foundation.Date` because the local ARM64 Windows Swift toolchain has
shown Foundation overlay issues. A SwiftUI-compatible `Date` initializer remains
planned.

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

## Foreground Style Modifier

`.foregroundStyle(_:)` exists as an inherited semantic text-color modifier.

```swift
VStack(spacing: 8) {
    Text("SwiftWinUI")
    Text("Native Windows, Swift-shaped.")
}
.foregroundStyle(.secondary)
```

The current implementation supports `.primary`, `.secondary`, `.accent`, and
`.destructive` foreground styles. It is intentionally much smaller than
SwiftUI's full `ShapeStyle` system: gradients, materials, hierarchical styles,
custom brushes, and non-text shape painting remain planned work.

## Background Modifier

`.background(_:)` exists for solid semantic colors.

```swift
VStack(spacing: 8) {
    Text("SwiftWinUI")
    Text("Native Windows, Swift-shaped.")
}
.padding(12)
.background(Color(red: 239, green: 246, blue: 255))
```

This is not yet the full SwiftUI background system. Arbitrary background views,
materials, alignment overloads, clipping, rounded corners, and exact paint-order
semantics are still planned.

## Border Modifier

`.border(_:width:)` exists for solid rectangular borders.

```swift
VStack(spacing: 8) {
    Text("SwiftWinUI")
    Text("Native Windows, Swift-shaped.")
}
.padding(12)
.background(Color(red: 239, green: 246, blue: 255))
.border(Color(red: 191, green: 219, blue: 254), width: 1)
.cornerRadius(10)
```

This is not yet a full SwiftUI overlay or shape-stroke system. Rounded borders,
shape styles, clipping, and exact modifier-order paint behavior remain planned.

## Corner Radius Modifier

`.cornerRadius(_:)` exists for SwiftWin decoration panels.

```swift
Text("Rounded panel")
    .padding(12)
    .background(Color(red: 239, green: 246, blue: 255))
    .border(Color(red: 191, green: 219, blue: 254), width: 1)
    .cornerRadius(10)
```

The current implementation rounds background and border drawing. It does not
clip descendant controls, so it is not yet equivalent to SwiftUI clipping.

## Hover State

Owner-drawn Win32 controls now react to explicit child-window hover tracking,
and SwiftWinUI exposes a SwiftUI-shaped `.onHover(perform:)` modifier.

Current compatibility limit: hover callbacks are attached to compatible child
controls that already participate in HWND tracking. SwiftUI can observe hover
over arbitrary view regions; SwiftWin will need a richer layout and hit-test
engine before container-level hover can match that behavior.

## Accessibility

SwiftWinUI now has SwiftUI-shaped accessibility metadata hooks:

```swift
TextField("Project name", text: $projectName)
    .accessibilityLabel("Project name")
    .accessibilityRole(.textField)
    .accessibilityValue(projectName)
```

Compatibility limit: the metadata is stored by the Win32 backend, but it is not
yet exposed through Microsoft UI Automation. Real assistive-technology support
needs that provider layer.

## Design Rules

- Prefer SwiftUI names over new names.
- Prefer SwiftUI initializer shapes and default arguments where possible.
- Prefer modifiers over one-off control-specific configuration.
- Keep Windows-specific details internal to renderers unless the user opts into them.
- When exact behavior is impossible, document the gap and keep the public API as close as possible.
- Avoid abstractions that would make future SwiftUI compatibility harder.

## Phase II Relationship

The project may add a traditional imperative Swift framework in parallel. If that layer makes implementation cleaner, the SwiftUI-compatible layer can wrap it internally while preserving SwiftUI-like public APIs.
