/// Boolean toggle in the declarative SwiftWinUI layer.
///
/// This uses callback-based changes until SwiftUI-compatible `Binding` exists.
public struct Toggle: View {
    private let title: String
    private let isOn: Bool
    private let onChange: ((Bool) -> Void)?

    /// Creates a toggle.
    public init(
        _ title: String,
        isOn: Bool = false,
        onChange: ((Bool) -> Void)? = nil
    ) {
        self.title = title
        self.isOn = isOn
        self.onChange = onChange
    }

    /// Emits a semantic toggle operation to the renderer.
    public func render(into context: RenderContext) {
        context.renderer.toggle(title, isOn: isOn, onChange: onChange)
    }
}
