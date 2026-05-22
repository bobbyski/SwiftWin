/// Boolean toggle in the declarative SwiftWinUI layer.
///
/// The binding initializer is the preferred SwiftUI-compatible surface; the
/// callback initializer remains useful for traditional event-style code.
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

    /// Creates a toggle bound to mutable state.
    public init(_ title: String, isOn: Binding<Bool>) {
        self.title = title
        self.isOn = isOn.wrappedValue
        self.onChange = { value in
            isOn.wrappedValue = value
        }
    }

    /// Emits a semantic toggle operation to the renderer.
    public func render(into context: RenderContext) {
        context.renderer.toggle(title, isOn: isOn, onChange: onChange)
    }
}
