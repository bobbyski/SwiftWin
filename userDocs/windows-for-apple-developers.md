# Windows Notes For Apple Developers

This page explains Windows concepts that may feel unusual if you come from macOS, iOS, AppKit, UIKit, SwiftUI, or `WKWebView`.

## HWND

`HWND` is the native Windows handle for both top-level windows and many controls.

On Apple platforms, you may think in terms of `NSWindow`, `NSView`, `UIView`, or SwiftUI views. In Win32, many controls are actual child windows with their own `HWND`.

## Message Loop

Win32 apps receive events through a message loop.

Examples:

- `WM_COMMAND`: button clicks and command events
- `WM_NOTIFY`: Common Controls notifications such as Date Time Picker changes
- `WM_DRAWITEM`: owner-drawn control rendering
- `WM_CTLCOLORSTATIC`: static text color/background customization
- `WM_DESTROY`: window teardown

This is lower-level than SwiftUI actions or AppKit delegate callbacks.

Some controls do not use the same message path. Buttons and edit controls
mostly report through `WM_COMMAND`, while richer Common Controls such as the
Win32 Date Time Picker report through `WM_NOTIFY` and pass a native struct such
as `SYSTEMTIME`. SwiftWin maps those details into plain Swift values like
`WinDate` and `CalendarDate`.

Another Date Time Picker oddity: keyboard editing is segmented by default. The
popup calendar behaves as expected, arrow keys adjust the active segment, and on
keyboards that expose Clear, the Clear key enables direct numeric entry.

## Child Window Scrolling

Win32 does not make a plain window scroll automatically.

The current prototype handles mouse-wheel scrolling by moving child `HWND`
controls and asking Windows to erase and repaint the client area. This is a
temporary window-level path. A real `ScrollView` / `WinScrollView` should own
clipping, scrollbars, nested content, and repaint behavior.

## Keyboard Traversal

Tab traversal is not automatic for a hand-built Win32 top-level window. SwiftWin
marks its window as a control parent and runs messages through
`IsDialogMessageW` so `WS_TABSTOP` child controls can move focus in document
order. Default buttons, cancel buttons, and app-level shortcuts are separate
command behaviors. SwiftWin now has a first-pass default command path for Enter
and an explicit cancel command path for Escape through `ButtonRole.cancel` /
`WinButtonRole.cancel`; richer app shortcuts remain planned.

Owner-drawn controls need their own focus visuals. Stock Windows controls paint
focus internally, but once SwiftWin takes over drawing for buttons, links,
segmented pickers, toggles, and swatches, the backend tracks `WM_SETFOCUS` and
`WM_KILLFOCUS` directly and paints a clear focus ring.

Native text fields use a different hook. SwiftWin handles `WM_CTLCOLOREDIT` to
give focused edit controls and the Date Time Picker's inner edit field a subtle
warm background, because their only stock focus hint may otherwise be the caret.

Default commands are another dialog behavior that plain windows do not get for
free. SwiftWin's first pass records the first primary button as the default
command and routes Enter to it, while leaving multiline editors free to handle
Return normally. Cancel commands work similarly: a semantic cancel button is
recorded and Escape routes to it before dialog translation can consume the key.

Hover is also per-child-window in the current backend. SwiftWin subclasses
tracked controls and uses `TrackMouseEvent` so owner-drawn controls can repaint
and `.onHover` / `WinHover` callbacks can receive enter and exit events.

Apple-platform mental model: this is closer to manually moving subviews and
forcing invalidation than to dropping content inside a ready-made
`NSScrollView`, `UIScrollView`, or SwiftUI `ScrollView`.

## Text Measurement And Clipping

Win32 text controls clip to the rectangle the app gives them. This differs from
the higher-level Apple-platform expectation that labels usually size themselves
from font metrics unless constrained by layout.

SwiftWinUI and SwiftWinLegacy should absorb this by default. The SDK's Win32
backend keeps shared text metrics for width and height so large titles, body
text, and descenders such as `y` and `g` render without app-level frame hacks.
Future layout work should replace these heuristics with real GDI measurement,
but the product rule stays the same: app code should feel Mac-like, and Windows
mechanics should be hidden behind polished defaults whenever practical.

## GDI Resources

## Accessibility

Apple developers may expect accessibility modifiers to flow straight into the
native accessibility tree. On Windows, the equivalent assistive-technology path
is Microsoft UI Automation. SwiftWin now records labels, roles, values, and
hints in framework metadata, but a UI Automation provider still needs to expose
that metadata to Narrator and other assistive tools.

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
- `comctl32`: Common Controls such as trackbars, progress bars, and date pickers
- `shell32`: shell integration such as opening URLs with `ShellExecuteW`
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
