/// Multi-line editable text control in the declarative SwiftWinUI layer.
///
/// This mirrors SwiftUI's `TextEditor` role for longer free-form text. The
/// current implementation supports string bindings and callback-style changes;
/// selection, find/replace, attributed text, and rich document editing remain
/// future work.
public struct TextEditor: View {
    private let prompt: String
    private let text: String
    private let textProvider: (() -> String)?
    private let onChange: ((String) -> Void)?

    /// Creates a multi-line text editor.
    public init(
        _ prompt: String = "",
        text: String = "",
        onChange: ((String) -> Void)? = nil
    ) {
        self.prompt = prompt
        self.text = text
        self.textProvider = nil
        self.onChange = onChange
    }

    /// Creates a multi-line text editor bound to mutable state.
    public init(_ prompt: String = "", text: Binding<String>) {
        self.prompt = prompt
        self.text = text.wrappedValue
        self.textProvider = { text.wrappedValue }
        self.onChange = { value in
            text.wrappedValue = value
        }
    }

    /// Emits a semantic text-editor operation to the renderer.
    public func render(into context: RenderContext) {
        context.renderer.textEditor(prompt, text: text, textProvider: textProvider, onChange: onChange)
    }
}
