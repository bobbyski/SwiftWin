/// Integer range slider in the declarative SwiftWinUI layer.
///
/// This uses callback-based changes until SwiftUI-compatible `Binding` exists.
public struct Slider: View {
    private let title: String
    private let value: Int
    private let range: ClosedRange<Int>
    private let onChange: ((Int) -> Void)?

    /// Creates a slider.
    public init(
        _ title: String,
        value: Int = 0,
        range: ClosedRange<Int> = 0...100,
        onChange: ((Int) -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.range = range
        self.onChange = onChange
    }

    /// Emits a semantic slider operation to the renderer.
    public func render(into context: RenderContext) {
        context.renderer.slider(title, value: value, range: range, onChange: onChange)
    }
}
