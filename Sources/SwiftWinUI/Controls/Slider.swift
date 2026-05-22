/// Integer range slider in the declarative SwiftWinUI layer.
///
/// The binding initializer is the preferred SwiftUI-compatible surface; the
/// callback initializer remains available for direct event handling.
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

    /// Creates a slider bound to mutable integer state.
    public init(
        _ title: String,
        value: Binding<Int>,
        range: ClosedRange<Int> = 0...100
    ) {
        self.title = title
        self.value = value.wrappedValue
        self.range = range
        self.onChange = { newValue in
            value.wrappedValue = newValue
        }
    }

    /// Emits a semantic slider operation to the renderer.
    public func render(into context: RenderContext) {
        context.renderer.slider(title, value: value, range: range, onChange: onChange)
    }
}
