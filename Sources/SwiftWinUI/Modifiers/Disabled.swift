/// A view that applies disabled state to its content.
///
/// This matches SwiftUI's `.disabled(_:)` modifier shape. The current Win32
/// backend maps it to native HWND enabled/disabled state for controls created
/// inside the scope.
public struct Disabled<Content: View>: View {
    private let isDisabled: Bool
    private let content: Content

    /// Creates a disabled-state wrapper.
    public init(isDisabled: Bool, content: Content) {
        self.isDisabled = isDisabled
        self.content = content
    }

    /// Emits disabled begin/end calls around the content.
    public func render(into context: RenderContext) {
        context.renderer.beginDisabled(isDisabled)
        content.render(into: context)
        context.renderer.endDisabled()
    }
}

public extension View {
    /// Disables or enables interactive controls inside this view.
    func disabled(_ isDisabled: Bool = true) -> Disabled<Self> {
        Disabled(isDisabled: isDisabled, content: self)
    }
}
