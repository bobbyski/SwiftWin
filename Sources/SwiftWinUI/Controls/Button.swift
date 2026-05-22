/// Clickable button in the declarative SwiftWinUI layer.
///
/// The current Windows path adapts this to `SwiftWinLegacy.WinButton`.
public struct Button: View {
    private let title: String
    private let style: ButtonStyle
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
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.action = action
    }

    /// Emits a semantic button operation to the renderer.
    public func render(into context: RenderContext) {
        context.renderer.button(title, style: style, action: action)
    }
}

/// Button visual role.
public enum ButtonStyle: Sendable, Hashable {
    /// Main action button.
    case primary
    /// Standard secondary action button.
    case secondary
}
