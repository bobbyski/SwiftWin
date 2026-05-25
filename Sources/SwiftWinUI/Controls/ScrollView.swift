/// A vertical scrolling container.
///
/// Compatibility note:
/// This intentionally starts with the most common SwiftUI shape:
/// `ScrollView { ... }`. Axis sets, indicators, reader/proxy support, and
/// nested scrolling are planned as the layout engine matures.
public struct ScrollView<Content: View>: View {
    private let content: Content

    /// Creates a vertical scroll view.
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    /// Emits a scroll-view scope around the content.
    public func render(into context: RenderContext) {
        context.renderer.beginScrollView()
        content.render(into: context)
        context.renderer.endScrollView()
    }
}
