/// A view that adds uniform padding around its content.
public struct Padding<Content: View>: View {
    private let amount: Double
    private let content: Content

    /// Creates a padded view.
    public init(amount: Double, content: Content) {
        self.amount = amount
        self.content = content
    }

    /// Emits padding begin/end calls around the content.
    public func render(into context: RenderContext) {
        context.renderer.beginPadding(amount)
        content.render(into: context)
        context.renderer.endPadding()
    }
}

public extension View {
    /// Adds uniform padding around this view.
    func padding(_ amount: Double = 8) -> Padding<Self> {
        Padding(amount: amount, content: self)
    }
}
