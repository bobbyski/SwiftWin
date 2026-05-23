/// A separator line in the declarative SwiftWinUI layer.
///
/// This mirrors SwiftUI's `Divider` role. The renderer chooses horizontal or
/// vertical orientation from the surrounding stack when possible.
public struct Divider: View {
    /// Creates a divider.
    public init() {}

    /// Emits a semantic divider operation to the renderer.
    public func render(into context: RenderContext) {
        context.renderer.divider()
    }
}
