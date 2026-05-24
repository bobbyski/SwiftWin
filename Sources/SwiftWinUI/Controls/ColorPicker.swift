/// Simple color picker in the declarative SwiftWinUI layer.
///
/// This first compatibility slice uses `Color` values from the current RGB
/// semantic color model. It supports callback and binding forms; a full
/// SwiftUI-style color model and native color dialog remain future work.
public struct ColorPicker: View {
    private let title: String
    private let color: Color
    private let colorProvider: (() -> Color)?
    private let onChange: ((Color) -> Void)?

    /// Creates a color picker.
    public init(
        _ title: String,
        color: Color = .accent,
        onChange: ((Color) -> Void)? = nil
    ) {
        self.title = title
        self.color = color
        self.colorProvider = nil
        self.onChange = onChange
    }

    /// Creates a color picker bound to mutable state.
    public init(_ title: String, selection: Binding<Color>) {
        self.title = title
        self.color = selection.wrappedValue
        self.colorProvider = { selection.wrappedValue }
        self.onChange = { value in
            selection.wrappedValue = value
        }
    }

    /// Emits a semantic color-picker operation to the renderer.
    public func render(into context: RenderContext) {
        context.renderer.colorPicker(title, color: color, colorProvider: colorProvider, onChange: onChange)
    }
}
