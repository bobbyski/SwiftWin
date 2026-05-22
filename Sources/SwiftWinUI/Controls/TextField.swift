/// Single-line editable text field in the declarative SwiftWinUI layer.
///
/// This is an early Milestone 2 control. The initializer is intentionally close
/// to SwiftUI's `TextField` label-first shape, but it uses an initial text
/// value and `onChange` callback until `Binding` exists.
public struct TextField: View {
    private let prompt: String
    private let text: String
    private let onChange: ((String) -> Void)?

    /// Creates a text field.
    public init(
        _ prompt: String,
        text: String = "",
        onChange: ((String) -> Void)? = nil
    ) {
        self.prompt = prompt
        self.text = text
        self.onChange = onChange
    }

    /// Emits a semantic text-field operation to the renderer.
    public func render(into context: RenderContext) {
        context.renderer.textField(prompt, text: text, onChange: onChange)
    }
}
