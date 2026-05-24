/// A view that observes pointer hover over compatible child controls.
///
/// Compatibility note:
/// This mirrors SwiftUI's `.onHover(perform:)` shape. The current Win32 backend
/// reports hover for native controls that already participate in HWND mouse
/// tracking; arbitrary container hit-testing will arrive with the richer layout
/// engine.
public struct Hover<Content: View>: View {
    private let onHover: (Bool) -> Void
    private let content: Content

    /// Creates a hover-observation wrapper.
    public init(onHover: @escaping (Bool) -> Void, content: Content) {
        self.onHover = onHover
        self.content = content
    }

    /// Emits hover begin/end calls around the content.
    public func render(into context: RenderContext) {
        context.renderer.beginHover(onHover)
        content.render(into: context)
        context.renderer.endHover()
    }
}

public extension View {
    /// Invokes `perform` when compatible child controls enter or exit hover.
    func onHover(perform: @escaping (Bool) -> Void) -> Hover<Self> {
        Hover(onHover: perform, content: self)
    }
}
