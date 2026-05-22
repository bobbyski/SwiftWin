/// A view that applies a text style to descendant text without explicit style.
///
/// This is an early SwiftUI-compatible `.font(...)` scope. It affects `Text`
/// values that do not pass an explicit `style:` argument.
public struct FontModifier<Content: View>: View {
    private let style: TextStyle
    private let content: Content

    /// Creates a font scope.
    public init(style: TextStyle, content: Content) {
        self.style = style
        self.content = content
    }

    /// Emits font begin/end calls around the content.
    public func render(into context: RenderContext) {
        context.renderer.beginFont(style)
        content.render(into: context)
        context.renderer.endFont()
    }
}

public extension View {
    /// Applies a text style to descendant text without explicit style.
    func font(_ style: TextStyle) -> FontModifier<Self> {
        FontModifier(style: style, content: self)
    }
}
