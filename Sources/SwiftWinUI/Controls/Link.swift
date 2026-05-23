/// Clickable external link in the declarative SwiftWinUI layer.
///
/// This mirrors SwiftUI's `Link` role for opening external destinations. The
/// first implementation uses string destinations to avoid pulling `Foundation`
/// into the current ARM64 Windows toolchain path, where importing it can hit a
/// UCRT overlay issue.
public struct Link: View {
    private let title: String
    private let destination: String

    /// Creates a link with a string destination.
    public init(_ title: String, destination: String) {
        self.title = title
        self.destination = destination
    }

    /// Emits a semantic link operation to the renderer.
    public func render(into context: RenderContext) {
        context.renderer.link(title, destination: destination)
    }
}
