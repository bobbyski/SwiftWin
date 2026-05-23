/// Segmented selection control in the declarative SwiftWinUI layer.
///
/// This early picker renders as radio-button options in the current Win32
/// backend. A more SwiftUI-compatible generic `Picker` shape can layer over
/// this once selection bindings and tags exist.
public struct Picker: View {
    private let title: String
    private let options: [String]
    private let selectedIndex: Int
    private let selectionProvider: (() -> Int)?
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
        self.selectionProvider = nil
        self.onChange = onChange
    }

    /// Creates a picker bound to mutable selection state.
    public init(
        _ title: String,
        options: [String],
        selectedIndex: Binding<Int>
    ) {
        self.title = title
        self.options = options
        self.selectedIndex = selectedIndex.wrappedValue
        self.selectionProvider = { selectedIndex.wrappedValue }
        self.onChange = { index in
            selectedIndex.wrappedValue = index
        }
    }

    /// Emits a semantic picker operation to the renderer.
    public func render(into context: RenderContext) {
        context.renderer.picker(title, options: options, selectedIndex: selectedIndex, selectionProvider: selectionProvider, onChange: onChange)
    }
}
