/// Integer stepper in the declarative SwiftWinUI layer.
///
/// This mirrors the common SwiftUI `Stepper` shape for integer state. Floating
/// point overloads and richer label builders remain planned.
public struct Stepper: View {
    private let title: String
    private let value: Int
    private let range: ClosedRange<Int>
    private let step: Int
    private let variant: StepperVariant
    private let onChange: ((Int) -> Void)?

    /// Creates a stepper.
    public init(
        _ title: String,
        value: Int = 0,
        range: ClosedRange<Int> = 0...100,
        step: Int = 1,
        variant: StepperVariant = .compact,
        onChange: ((Int) -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.range = range
        self.step = step
        self.variant = variant
        self.onChange = onChange
    }

    /// Creates a stepper bound to mutable integer state.
    public init(
        _ title: String,
        value: Binding<Int>,
        range: ClosedRange<Int> = 0...100,
        step: Int = 1,
        variant: StepperVariant = .compact
    ) {
        self.title = title
        self.value = value.wrappedValue
        self.range = range
        self.step = step
        self.variant = variant
        self.onChange = { newValue in
            value.wrappedValue = newValue
        }
    }

    /// Emits a semantic stepper operation to the renderer.
    public func render(into context: RenderContext) {
        context.renderer.stepper(title, value: value, range: range, step: step, variant: variant, onChange: onChange)
    }
}

/// Stepper visual variants supported by SwiftWinUI.
public enum StepperVariant: Sendable, Hashable {
    /// Title/value label with adjacent decrement and increment buttons.
    case compact
    /// Title label with decrement, value, and increment integrated into one row.
    case integratedValue
}
