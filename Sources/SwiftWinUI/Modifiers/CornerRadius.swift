/// Modifier that applies a corner radius to compatible decorations.
///
/// Current scope:
/// This affects `background` and `border` panels. It does not yet clip child
/// controls or provide SwiftUI's full shape-based clipping behavior.
public struct CornerRadiusModifier<Content: View>: View {
    private let radius: Double
    private let content: Content

    /// Creates a corner-radius wrapper.
    public init(radius: Double, content: Content) {
        self.radius = radius
        self.content = content
    }

    /// Emits corner-radius scope calls around the wrapped content.
    public func render(into context: RenderContext) {
        context.renderer.beginCornerRadius(radius)
        content.render(into: context)
        context.renderer.endCornerRadius()
    }
}

public extension View {
    /// Applies a corner radius to compatible decoration modifiers.
    func cornerRadius(_ radius: Double) -> CornerRadiusModifier<Self> {
        CornerRadiusModifier(radius: radius, content: self)
    }
}
