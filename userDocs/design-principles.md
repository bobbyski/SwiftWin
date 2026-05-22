# Design Principles

SwiftWinUI is being built as a pair of related libraries:

- `SwiftWinLegacy`: the traditional imperative foundation.
- `SwiftWinUI`: the SwiftUI-compatible declarative layer.

The two layers should share behavior wherever practical. The current direction is to build native concepts in `SwiftWinLegacy` first, then wrap them from `SwiftWinUI`.

## Small Functions

Functions should stay as small as reasonably practical.

Small functions make the Windows runtime easier to audit because Win32 code often mixes several concerns that Apple-platform developers may expect to be separate: handle creation, message routing, layout, resource lifetime, drawing, and event callbacks.

When a function starts doing more than one of those jobs, prefer extracting the next named operation.

## Protocol-Oriented Boundaries

Use protocols where they create useful boundaries:

- app runners
- layout containers
- text-displaying elements
- titled controls
- action controls
- button-like controls
- future native handle providers
- future renderers and layout engines

Protocols should improve type safety, interoperability, testing, or custom implementations. Avoid adding protocols only for ceremony.

## Default Implementations

Concrete classes such as `WinApplication`, `WinStack`, `WinText`, and `WinButton` are default implementations of public contracts.

Future apps should be able to introduce custom controls or alternate runtimes without forking the framework.

## SwiftUI Compatibility

The declarative layer should continue to prefer SwiftUI-compatible API shapes. Protocol-oriented internals are useful only if they keep that goal easier, not harder.

When exact SwiftUI behavior is not possible on Windows, the public API should stay as SwiftUI-shaped as possible and the difference should be documented.

## Windows Note For Apple Developers

Win32 controls are usually child windows with `HWND` handles. That means a SwiftWin control may eventually need both a high-level Swift protocol and a carefully managed native handle behind it. The public protocol should describe the safe Swift behavior first; raw handle access should be an explicit advanced escape hatch.
