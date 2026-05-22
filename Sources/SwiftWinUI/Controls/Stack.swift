/// Vertical stack layout container.
public struct VStack<Content: View>: View {
    private let spacing: Double
    private let content: Content

    /// Creates a vertical stack.
    public init(spacing: Double = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    /// Emits stack begin/end calls around the child content.
    public func render(into context: RenderContext) {
        context.renderer.beginStack(axis: .vertical, spacing: spacing)
        content.render(into: context)
        context.renderer.endStack()
    }
}

/// Horizontal stack layout container.
public struct HStack<Content: View>: View {
    private let spacing: Double
    private let content: Content

    /// Creates a horizontal stack.
    public init(spacing: Double = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    /// Emits stack begin/end calls around the child content.
    public func render(into context: RenderContext) {
        context.renderer.beginStack(axis: .horizontal, spacing: spacing)
        content.render(into: context)
        context.renderer.endStack()
    }
}
