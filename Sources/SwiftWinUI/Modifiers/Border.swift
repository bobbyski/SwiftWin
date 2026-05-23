/// Modifier that paints a solid border around content.
///
/// Current scope:
/// This first compatibility slice supports solid rectangular borders. SwiftUI's
/// richer overlay, shape, stroke style, and rounded border APIs remain planned.
public struct BorderModifier<Content: View>: View {
    private let color: Color
    private let width: Double
    private let content: Content

    /// Creates a solid border wrapper.
    public init(color: Color, width: Double, content: Content) {
        self.color = color
        self.width = width
        self.content = content
    }

    /// Emits border scope calls around the wrapped content.
    public func render(into context: RenderContext) {
        context.renderer.beginBorder(color, width: width)
        content.render(into: context)
        context.renderer.endBorder()
    }
}

public extension View {
    /// Paints a solid rectangular border around this view.
    func border(_ color: Color, width: Double = 1) -> BorderModifier<Self> {
        BorderModifier(color: color, width: width, content: self)
    }
}
