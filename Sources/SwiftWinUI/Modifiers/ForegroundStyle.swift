/// Modifier that applies an inherited foreground style to descendant views.
///
/// Current scope:
/// Text honors this modifier today. Future controls and custom drawing surfaces
/// can opt in through the same renderer foreground-style stack.
public struct ForegroundStyleModifier<Content: View>: View {
    private let style: ForegroundStyle
    private let content: Content

    /// Creates a foreground-style scope around content.
    public init(style: ForegroundStyle, content: Content) {
        self.style = style
        self.content = content
    }

    /// Emits foreground scope calls around the wrapped content.
    public func render(into context: RenderContext) {
        context.renderer.beginForegroundStyle(style)
        content.render(into: context)
        context.renderer.endForegroundStyle()
    }
}

public extension View {
    /// Applies a semantic foreground style to descendant views.
    func foregroundStyle(_ style: ForegroundStyle) -> ForegroundStyleModifier<Self> {
        ForegroundStyleModifier(style: style, content: self)
    }
}
