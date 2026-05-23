/// Single-line editable text field in the declarative SwiftWinUI layer.
///
/// This is an early Milestone 2 control. It supports both the original
/// callback initializer and a SwiftUI-shaped `Binding` initializer.
public struct TextField: View {
    private let prompt: String
    private let text: String
    private let textProvider: (() -> String)?
    private let onChange: ((String) -> Void)?

    /// Creates a text field.
    public init(
        _ prompt: String,
        text: String = "",
        onChange: ((String) -> Void)? = nil
    ) {
        self.prompt = prompt
        self.text = text
        self.textProvider = nil
        self.onChange = onChange
    }

    /// Creates a text field bound to mutable state.
    public init(_ prompt: String, text: Binding<String>) {
        self.prompt = prompt
        self.text = text.wrappedValue
        self.textProvider = { text.wrappedValue }
        self.onChange = { value in
            text.wrappedValue = value
        }
    }

    /// Emits a semantic text-field operation to the renderer.
    public func render(into context: RenderContext) {
        context.renderer.textField(prompt, text: text, textProvider: textProvider, onChange: onChange)
    }
}
