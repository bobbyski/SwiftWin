/// Imperative button element.
public final class WinButton: WinButtonDisplaying {
    /// Text shown on the button.
    public var title: String
    /// Visual role for the button.
    public var style: WinButtonStyle
    /// Semantic command role for keyboard routing and future styling.
    public var role: WinButtonRole?
    /// Closure invoked when native command routing reports a click.
    public var action: () -> Void

    /// Creates a button.
    public init(
        _ title: String,
        style: WinButtonStyle = .secondary,
        role: WinButtonRole? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.role = role
        self.action = action
    }
}

/// Button visual role.
public enum WinButtonStyle: Sendable, Hashable {
    /// Main action button.
    case primary
    /// Standard secondary action button.
    case secondary
}

/// Semantic button command role.
///
/// This mirrors SwiftUI's `ButtonRole` idea without forcing every style choice
/// through platform-specific button classes. The Win32 backend uses the role
/// for keyboard command routing first; visual role styling can grow later.
public enum WinButtonRole: Sendable, Hashable {
    /// Cancel command, activated by Escape when registered.
    case cancel
    /// Destructive command, reserved for future styling and accessibility.
    case destructive
}
