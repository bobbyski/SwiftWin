# SwiftUI And Windows Control Comparison

This matrix compares SwiftUI view types with likely Windows-native counterparts for SwiftWinUI and SwiftWinLegacy.

Milestone numbers line up with the project plan:

- M1: native prototype
- M2: usable mini framework
- M3: app-quality Windows UI
- M4: framework boundary and embedding
- M5: SwiftUI compatibility push
- M6: real viability application

## Shared Or Closely Mappable Views

| Milestone | SwiftUI View Type | SwiftWinUI / SwiftWinLegacy Target | Win32 Counterpart | WinUI Counterpart | Backend | Implementation Notes |
| --- | --- | --- | --- | --- | --- | --- |
| M1 | `Text` | `Text` / `WinText` | `STATIC` | `TextBlock` | Win32 now, WinUI later | Implemented as native static text. Dynamic text refresh exists. Rich text, wrapping, selection, and accessibility remain planned. |
| M1 | `Button` | `Button` / `WinButton` | `BUTTON` with `BS_OWNERDRAW` | `Button` | Win32 now, WinUI later | Implemented with actions, owner-drawn primary/secondary styles, hover/pressed/disabled/focused paint, Enter default-command routing, and Escape cancel routing through semantic button roles. |
| M2 | `ButtonRole` | `ButtonRole` / `WinButtonRole` | Command metadata over `BUTTON` | Button command metadata | Framework + backend | `.cancel` is implemented and routes Escape. `.destructive` is present as semantic metadata; destructive styling/accessibility remain planned. |
| M1 | `Spacer` | `Spacer` / `WinSpacer` | None; layout gap | Layout spacing/flexible panel behavior | Framework | Implemented as fixed spacing. SwiftUI-compatible flexible expansion remains planned. |
| M2 | `TextField` | `TextField` / `WinTextField` | `EDIT` | `TextBox` | Win32 now, WinUI later | Implemented as single-line edit control with callback and binding paths. Validation, selection events, and multiline text remain planned. |
| M2 | `SecureField` | `SecureField` / `WinSecureField` | `EDIT` with `ES_PASSWORD` | `PasswordBox` | Win32 now, WinUI later | Implemented with masked native input, callback and binding paths, and redacted console diagnostics. Reveal controls, submit handling, clipboard policy, and stronger credential helpers remain planned. |
| M2 | `Toggle` | `Toggle` / `WinToggle` | `BUTTON` checkbox or owner-drawn checkbox | `CheckBox`, `ToggleSwitch` | Win32 now, WinUI later | Implemented as owner-drawn checkbox row. SwiftUI toggle styles can later map to checkbox, switch, or custom drawing. |
| M2 | `Picker` | `Picker` / `WinPicker` | Radio buttons, combo box, list box, owner-drawn segments | `ComboBox`, `RadioButtons`, `TabView` | Win32 now, WinUI later | Implemented as segmented picker. Generic picker tags and style variants remain planned. |
| M2 | `Slider` | `Slider` / `WinSlider` | Common Controls trackbar | `Slider` | Win32 now, WinUI later | Implemented for integer ranges. SwiftUI-compatible floating point and step behavior remain planned. |
| M2 | `Divider` | `Divider` / `WinSeparator` | Static line, custom paint, etched frame | `Rectangle`, `Border` | Framework / custom | Implemented as owner-drawn `WinSeparator`; orientation is inferred from the surrounding stack in SwiftWinUI. |
| M2 | `ProgressView` | `ProgressView` / `WinProgressView` | Progress bar common control | `ProgressBar`, `ProgressRing` | Win32 now, WinUI later | Implemented for determinate progress. Indeterminate progress and ring-style progress remain planned; those map more naturally to WinUI or custom drawing than stock Win32. |
| M2 | `Stepper` | `Stepper` / `WinStepper` | Composite buttons now; up-down control later | `NumberBox` or custom stepper | Framework / Win32 now, WinUI later | Implemented for integer values with compact and integrated-value variants. Numeric text entry, floating-point values, and native up-down control exploration remain planned. |
| M2 | `DatePicker` | `DatePicker` / `WinDatePicker` | Date/time picker common control | `DatePicker`, `TimePicker`, `CalendarDatePicker` | Win32 now, WinUI later | First pass implemented as a date-only Win32 Date Time Picker using a toolchain-safe `CalendarDate` / `WinDate` value. SwiftUI-compatible `Foundation.Date`, time styles, ranges, displayed components, and locale formatting remain planned. |
| M2 | `ColorPicker` | `ColorPicker` / `WinColorPicker` | Owner-drawn swatch plus Color common dialog | `ColorPicker` | Framework / Win32 now, WinUI later | Implemented with a custom swatch surface and `ChooseColorW` for native color selection. A richer SwiftUI color model, opacity, color spaces, and inline picker styles remain planned. |
| M2 | `Link` | `Link` / `WinLink` | Owner-drawn clickable text plus `ShellExecuteW`; SysLink later | `HyperlinkButton` | Win32 now, WinUI later | Implemented with shell-dispatched URL/protocol opening, hover/pressed paint, and string destinations. SwiftUI-compatible `URL` initializer is planned once Foundation import is safe on the current ARM64 Windows toolchain. |
| M2 | `TextEditor` | `TextEditor` / `WinTextEditor` | Multiline `EDIT` now; Rich Edit later | Multiline `TextBox`, `RichEditBox` | Win32 now, WinUI later | Implemented for plain multi-line text with callback and binding paths. Serious editing, rich text, syntax highlighting, and find/replace need Rich Edit or WebView/Monaco. |
| M3 | `List` | `List` / `WinList` | ListView common control, owner-data ListView, or custom rows | `ListView` | Win32 or WinUI | Not implemented. Needs row identity, selection, scrolling, diffing, and virtualization. |
| M3 | `Table` | `Table` / `WinTable` | ListView report mode | `ListView`; no base WinUI `DataGrid` | Win32 or WinUI/custom | Not implemented. Win32 report ListView is a strong dense-data candidate. |
| M3 | `DisclosureGroup` | `DisclosureGroup` / `WinDisclosureGroup` | Custom button plus child layout | `Expander` | Framework / WinUI | Not implemented. Best built from state, button, and conditional child layout. |
| M3 | `OutlineGroup` | `OutlineGroup` / `WinOutlineGroup` | TreeView common control | `TreeView` | Win32 or WinUI | Not implemented. TreeView maps conceptually, but data-driven expansion and identity need adapter work. |
| M3 | `Image` | `Image` / `WinImage` | `STATIC` bitmap/icon, WIC, GDI+, Direct2D | `Image` | Win32 custom or WinUI | Not implemented. Needs asset loading, DPI scaling, transparency, and format strategy. |
| M3 | `AsyncImage` | `AsyncImage` | Same as `Image` plus async loading/cache | `Image` plus async source | Framework | Not implemented. Needs cancellation, cache policy, placeholder, and error states. |
| M3 | `Gauge` | `Gauge` / `WinGauge` | No direct stock equivalent | `ProgressBar` or custom radial gauge | Custom / WinUI | Not implemented. Should be a styleable framework view, not a stock Win32 control. |
| M5 | `Label` | `Label` / `WinLabel` | `STATIC` plus icon/image | `TextBlock` plus icon element | Framework layout + backend | Not implemented. Should be composition of icon/image and text once image support exists. |
| M5 | `Menu` | `Menu` / `WinMenu` | Menu bar, popup menu, command IDs | `MenuFlyout`, `MenuBar` | Win32 or WinUI | Not implemented. Win32 menus are command/message based; SwiftUI menus are declarative command trees. |
| M5 | `WebView` | `WebView` / `WinWebView` | Edge WebView2 child controller, not classic Win32 | WebView2 | WebView2 | Planned. Windows equivalent is Edge WebView2, with Chromium/WebAssembly support. Requires COM or shim layer. |

## Layout And Composition Views

| Milestone | SwiftUI View Type | SwiftWinUI / SwiftWinLegacy Target | Win32 Counterpart | WinUI Counterpart | Backend | Implementation Notes |
| --- | --- | --- | --- | --- | --- | --- |
| M1 | `VStack` | `VStack` / `WinStack(.vertical)` | None; framework layout | `StackPanel` | Framework now, WinUI possible | Implemented as direct placement. Needs real measure/place, alignment, flexible sizing, and resize behavior. |
| M1 | `HStack` | `HStack` / `WinStack(.horizontal)` | None; framework layout | `StackPanel` | Framework now, WinUI possible | Implemented as direct placement. Needs the same layout engine work as `VStack`. |
| M1 | `EmptyView` | `EmptyView` | None | None | Framework | Implemented. Emits no native controls. |
| M1 | `AnyView` | `AnyView` | None | None | Framework | Implemented as type erasure for the current render stream. |
| M1 | `TupleView` | `TupleView` | None | None | Framework | Implemented as a result-builder compatibility bridge. |
| M2 | `Group` | `Group` | None | None | Framework | Not implemented. Should group declarations without creating native UI. |
| M2 | `Form` | `Form` / `WinForm` | Framework layout over controls | `StackPanel`, `Grid`, item composition | Framework | Not implemented. `Form` is semantic layout with sections, labels, validation, and platform spacing. |
| M3 | `ZStack` | `ZStack` / `WinZStack` | Overlapping child HWNDs or custom paint | `Grid` overlay | Framework | Not implemented. Needs z-order and hit-testing behavior. Child HWND z-order can be awkward. |
| M3 | `Grid` | `Grid` / `WinGrid` | Framework layout | `Grid` | Framework / WinUI | Not implemented. Best implemented in framework for Win32; WinUI has a real Grid. |
| M2 | `ScrollView` | `ScrollView` / `WinScrollView` | Scoped child HWND movement and visibility clipping | `ScrollViewer` | Win32 now partial, WinUI later | First-pass vertical scroll view exists with wheel scrolling, Page Up/Page Down/Home/End keyboard scrolling, repaint hardening, and lightweight visual indicators. Native draggable scrollbar thumbs, nested scrolling, and robust clipping remain planned. |
| M3 | `Section` | `Section` / `WinSection` | Group box or framework layout | `Expander`, custom layout | Framework | Not implemented. Visual treatment depends on parent `Form`, `List`, or settings page style. |
| M3 | `TabView` | `TabView` / `WinTabView` | Tab common control | `TabView` | Win32 or WinUI | Not implemented. Win32 tabs are functional but old-looking; modern tabs may need WinUI or owner draw. |
| M4 | `LazyVStack` / `LazyHStack` | Lazy stack views | None; virtualization/custom layout | `ItemsRepeater`, `ListView` | Framework / WinUI | Not implemented. Requires virtualization and stable identity. |
| M4 | `LazyVGrid` / `LazyHGrid` | Lazy grid views | ListView icon/tile modes or custom layout | `ItemsRepeater`, `GridView` | Framework / WinUI | Not implemented. Win32 ListView can cover some icon/grid cases, but SwiftUI layout compatibility is broader. |
| M5 | `NavigationStack` | `NavigationStack` | Framework state and layout | `Frame`, `NavigationView` | Framework / WinUI | Not implemented. Needs routing, title/toolbar coordination, and view identity. |
| M5 | `NavigationSplitView` | `NavigationSplitView` | Splitter panes/custom layout | `NavigationView`, `Grid`, `SplitView` | Framework / WinUI | Not implemented. Important for desktop productivity apps; needs resizable panes and selection state. |

## Modifiers And Semantic APIs

| Milestone | SwiftUI API | SwiftWinUI Target | Win32 Counterpart | WinUI Counterpart | Backend | Implementation Notes |
| --- | --- | --- | --- | --- | --- | --- |
| M2 | `.padding(_:)` | `Padding` / `WinPadding` | Framework layout | Margin/padding properties | Framework | Implemented as uniform padding. Edge-specific padding is planned. |
| M2 | `.frame(width:height:)` | `Frame` / `WinFrame` | Framework layout proposal | Width/Height properties | Framework | Implemented as fixed-size hint. Min/max/alignment overloads remain planned. |
| M2 | `.disabled(_:)` | `Disabled` / `WinDisabled` | `EnableWindow` | `IsEnabled` | Win32 now, WinUI later | Implemented. Dynamic disabled state needs reconciliation to update after state changes. |
| M3 | `.font(_:)` | Font modifier | `HFONT` | Font properties | Framework + backend | Partial. Semantic `TextStyle` values now inherit through descendant `Text`; custom families, dynamic type, and font composition remain planned. |
| M3 | `.foregroundStyle(_:)` | Foreground style modifier | Text color, brush, pen | Foreground brush | Framework + backend | Partial. Semantic foreground colors now inherit through descendant `Text`; gradients, materials, custom brushes, and non-text painting remain planned. |
| M3 | `.background(_:)` | Background modifier | Brush fill/custom paint | Background brush | Framework + backend | Partial. Solid color backgrounds exist through `WinBackground`; arbitrary background views, materials, clipping, and exact paint order remain planned. |
| M3 | `.border(_:)` / `.overlay(_:)` | Decoration modifiers | Custom drawing, border styles | Border, overlay composition | Framework + backend | Partial. `.border(_:width:)` exists through `WinBorder`; overlay, shape strokes, clipping, and exact paint-order semantics remain planned. |
| M3 | `.cornerRadius(_:)` | Corner radius modifier | Rounded GDI drawing / clipping regions | CornerRadius / Clip | Framework + backend | Partial. Background and border decorations can round corners; descendant clipping remains planned. |
| M3 | `.onTapGesture` | Gesture/action modifier | Mouse messages, hit testing | Pointer/tap events | Framework + backend | Not implemented. Buttons should remain buttons; gesture modifiers need a general event layer. |
| M2 | `.onHover` | `Hover` / `WinHover` | Child HWND subclassing / `TrackMouseEvent` | Pointer entered/exited | Framework + backend | Implemented for compatible child controls that already participate in HWND mouse tracking. Arbitrary layout-region hover awaits the real layout/hit-test engine. |
| M2 | `.keyboardShortcut` | `KeyboardShortcutModifier` / `WinKeyboardShortcut` | Explicit `WM_KEYDOWN` command routing | Keyboard accelerators / command routing | Framework + backend | First pass implemented for letter and number shortcuts. `.command` maps to Control on Windows for Apple-oriented source compatibility. Menu integration and symbolic keys remain planned. |
| M2 | `.accessibilityLabel` / `.accessibilityValue` / `.accessibilityRole` / `.accessibilityHint` | `AccessibilityModifier` / `WinAccessibility` | Stored metadata now; Microsoft UI Automation later | AutomationProperties | Framework now, backend later | Metadata hooks implemented for labels, roles, values, and hints. Full screen-reader exposure needs a UI Automation provider. |

## SwiftUI Views Without Direct Windows Equivalents

| Milestone | SwiftUI View Type | Windows Status | Win32 / WinUI Notes | Implementation Notes |
| --- | --- | --- | --- | --- |
| M3 | `Canvas` | No stock control | Direct2D, DirectWrite, or custom drawing | Should be a retained/custom drawing surface, not child HWND composition. |
| M3 | `GeometryReader` | No stock control | Layout measurement callback | Requires a real measure/place layout pass. |
| M3 | `ViewThatFits` | No stock control | Layout engine chooses first fitting child | Requires proposed-size measurement and child size evaluation. |
| M4 | `TimelineView` | No stock control | Timer-driven invalidation | Needs render invalidation and an animation/timer loop. |
| M5 | `ShareLink` | No classic Win32 equivalent | Windows share contracts are not simple Win32 controls | May require Windows App SDK integration or remain unsupported initially. |
| M5 | `PhotosPicker` | Apple-specific | Windows file/media picker concepts differ | Should not be considered source-compatible without a custom abstraction. |
| M5 | `Map` | No base SwiftUI equivalent on Windows | WebView2 map, Maps SDK, or provider package | Likely optional, backed by WebView2 or a mapping SDK. |
| M6 | `VideoPlayer` | No direct Win32 control | Media Foundation, WebView2, or WinUI media controls | Best as an optional media package. |
| M6 | `RealityView` | Apple platform-specific | No stock Windows UI counterpart | Out of core scope unless a 3D/AR backend is deliberately added. |
| M6 | `SceneView` | Apple framework-specific | Direct3D/Metal alternatives differ | Out of core scope. |

## Windows Controls Without Direct SwiftUI Equivalents

| Milestone | Windows Control Or Pattern | Win32 Counterpart | WinUI Counterpart | Possible SwiftWin API | Implementation Notes |
| --- | --- | --- | --- | --- | --- |
| M2 | Task dialog | `TaskDialogIndirect` | `ContentDialog` | `WinTaskDialog`, richer `Dialog` variants | Better than message box for command links, verification checkboxes, and richer prompts. |
| M3 | Group box | `BUTTON` group-box style | GroupBox pattern/custom | `WinGroupBox`, SwiftUI `GroupBox` wrapper | SwiftUI has `GroupBox`, but Windows group boxes can look dated; custom modern style may be preferable. |
| M3 | Status bar | Status bar common control | Custom command/status area | `WinStatusBar`, toolbar/status modifier | Common in desktop Windows apps. SwiftUI does not have a perfect direct view type. |
| M3 | Tree view | TreeView common control | `TreeView` | `WinTreeView`, backs `OutlineGroup` or navigation | Useful for file/project explorers. Needs selection, icons, expansion, and keyboard handling. |
| M3 | Rich Edit | Rich Edit control | `RichEditBox` | `WinRichTextEditor` | Advanced text editing should not be implemented on plain `EDIT`. |
| M3 | Split button | Button plus popup/menu | `SplitButton` | `WinSplitButton` | SwiftUI `Menu` can cover many cases, but Windows has a distinct split-button pattern. |
| M4 | File dialogs | Common Item Dialog COM APIs | File picker APIs | `WinOpenPanel`, `WinSavePanel` | SwiftUI has file importer/exporter concepts; Windows implementation likely uses COM dialogs. |
| M4 | Notify icon | Shell notification icon APIs | App notification APIs | `WinTrayIcon` | No direct SwiftUI view. Important for Windows utilities. |
| M4 | Command bar / ribbon | Toolbar, rebar, ribbon framework | `CommandBar` | `WinCommandBar`, SwiftUI `Toolbar` backend | Real productivity apps need command routing. Ribbon should be optional. |
| M5 | Property sheet / tabbed dialog | Property sheet APIs | `TabView`, custom pages | `WinPropertySheet` | Traditional Windows pattern; may belong mostly in SwiftWinLegacy. |
| M5 | Rebar / command bands | Rebar common control | CommandBar / AppBar | Probably Legacy-only | Very Windows-specific and visually dated. |
| M5 | WebView2 | WebView2 COM controller | WebView2 | `WinWebView`, SwiftUI `WebView` | Required for embedded web, Monaco, and WebAssembly. |

## Backend Choice Notes

| Milestone | Area | Prefer Win32 | Prefer WinUI | Prefer Custom / Direct2D |
| --- | --- | --- | --- | --- |
| M2 | Basic controls | Good for current prototype and low dependency footprint | Better modern visuals if Windows App SDK integration is practical | Useful when SwiftUI behavior needs to override stock native behavior |
| M3 | Dense lists and tables | Strong via ListView and TreeView | Good for modern app style | Needed for full custom rows and virtualization |
| M3 | Modern styling | Requires owner draw/custom paint | Stronger defaults | Strongest control over visual identity |
| M3 | Animation and canvas | Weak in plain GDI | Better composition support | Direct2D/DirectWrite likely best |
| M5 | Web content | WebView2 is required either way | WebView2 is still the answer | Not applicable |
| M5 | SwiftUI compatibility | Needs framework layout/reconciliation above Win32 | Easier property mapping for some controls | Needed for layout, modifiers, custom drawing, and exact semantics |
