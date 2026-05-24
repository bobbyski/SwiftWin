/// Clickable button in the declarative SwiftWinUI layer.
///
/// The current Windows path adapts this to `SwiftWinLegacy.WinButton`.
public struct Button: View {
    private let title: String
    private let style: ButtonStyle
    private let role: ButtonRole?
    private let action: () -> Void

    /// Creates a button.
    ///
    /// - Parameters:
    ///   - title: Text shown on the button.
    ///   - style: Visual role for the button.
    ///   - action: Closure invoked when native command routing reports a click.
    public init(
        _ title: String,
        style: ButtonStyle = .secondary,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.role = role
        self.action = action
    }

    /// Emits a semantic button operation to the renderer.
    public func render(into context: RenderContext) {
        context.renderer.button(title, style: style, role: role, action: action)
    }
}

/// Button visual role.
public enum ButtonStyle: Sendable, Hashable {
    /// Main action button.
    case primary
    /// Standard secondary action button.
    case secondary
}

/// Semantic button role.
///
/// The shape intentionally follows SwiftUI's `ButtonRole` so app code can mark
/// cancel and destructive commands without inventing Windows-specific APIs.
public enum ButtonRole: Sendable, Hashable {
    /// Cancel command, activated by Escape when a backend supports it.
    case cancel
    /// Destructive command, reserved for future styling and accessibility.
    case destructive
}
