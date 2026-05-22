/// A view that proposes a fixed width and/or height to its content.
///
/// This mirrors the common SwiftUI `.frame(width:height:)` spelling. The
/// current renderer treats it as a fixed-size layout hint; richer min/max and
/// alignment behavior will arrive with the full layout engine.
public struct Frame<Content: View>: View {
    private let width: Double?
    private let height: Double?
    private let content: Content

    /// Creates a fixed-size frame around content.
    public init(width: Double?, height: Double?, content: Content) {
        self.width = width
        self.height = height
        self.content = content
    }

    /// Emits frame begin/end calls around the content.
    public func render(into context: RenderContext) {
        context.renderer.beginFrame(width: width, height: height)
        content.render(into: context)
        context.renderer.endFrame()
    }
}

public extension View {
    /// Proposes a fixed width and/or height for this view.
    func frame(width: Double? = nil, height: Double? = nil) -> Frame<Self> {
        Frame(width: width, height: height, content: self)
    }
}
