/// Imperative button element.
public final class WinButton: WinButtonDisplaying {
    /// Text shown on the button.
    public var title: String
    /// Visual role for the button.
    public var style: WinButtonStyle
    /// Closure invoked when native command routing reports a click.
    public var action: () -> Void

    /// Creates a button.
    public init(_ title: String, style: WinButtonStyle = .secondary, action: @escaping () -> Void) {
        self.title = title
        self.style = style
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
