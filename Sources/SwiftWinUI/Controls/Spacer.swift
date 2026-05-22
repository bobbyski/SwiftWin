/// Inserts space in the current layout.
///
/// Current behavior is fixed spacing in the legacy renderer. A flexible
/// SwiftUI-compatible spacer is planned once the layout engine exists.
public struct Spacer: View {
    /// Creates a spacer.
    public init() {}

    /// Emits a spacer operation.
    public func render(into context: RenderContext) {
        context.renderer.spacer()
    }
}
