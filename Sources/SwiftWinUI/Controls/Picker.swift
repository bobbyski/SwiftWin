/// Segmented selection control in the declarative SwiftWinUI layer.
///
/// This early picker renders as radio-button options in the current Win32
/// backend. A more SwiftUI-compatible generic `Picker` shape can layer over
/// this once selection bindings and tags exist.
public struct Picker: View {
    private let title: String
    private let options: [String]
    private let selectedIndex: Int
    private let onChange: ((Int) -> Void)?

    /// Creates a picker.
    public init(
        _ title: String,
        options: [String],
        selectedIndex: Int = 0,
        onChange: ((Int) -> Void)? = nil
    ) {
        self.title = title
        self.options = options
        self.selectedIndex = selectedIndex
        self.onChange = onChange
    }

    /// Emits a semantic picker operation to the renderer.
    public func render(into context: RenderContext) {
        context.renderer.picker(title, options: options, selectedIndex: selectedIndex, onChange: onChange)
    }
}
