/// Modifier that paints a solid background behind content.
///
/// Current scope:
/// This first compatibility slice supports solid semantic colors. SwiftUI's
/// full background overload family, materials, alignment, and arbitrary views
/// remain planned.
public struct BackgroundModifier<Content: View>: View {
    private let color: Color
    private let content: Content

    /// Creates a solid background wrapper.
    public init(color: Color, content: Content) {
        self.color = color
        self.content = content
    }

    /// Emits background scope calls around the wrapped content.
    public func render(into context: RenderContext) {
        context.renderer.beginBackground(color)
        content.render(into: context)
        context.renderer.endBackground()
    }
}

public extension View {
    /// Paints a solid semantic color behind this view.
    func background(_ color: Color) -> BackgroundModifier<Self> {
        BackgroundModifier(color: color, content: self)
    }
}
