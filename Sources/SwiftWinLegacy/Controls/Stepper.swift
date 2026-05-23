/// Integer stepper in the traditional API.
///
/// The current Win32 backend renders this as a small composite control made
/// from a value label and two owner-drawn buttons. That keeps the behavior
/// portable while the layout and numeric-entry story are still evolving.
public final class WinStepper: WinRangeControl {
    /// Label describing the stepped value.
    public var title: String
    /// Current value.
    public var value: Int
    /// Minimum allowed value.
    public var minimum: Int
    /// Maximum allowed value.
    public var maximum: Int
    /// Amount added or subtracted for each step action.
    public var step: Int
    /// Visual arrangement used by the backend.
    public var variant: WinStepperVariant
    /// Closure invoked when native interaction changes the value.
    public var onChange: ((Int) -> Void)?
    /// Optional source of truth used when external state invalidates the view.
    public var valueProvider: (() -> Int)?

    /// Creates a stepper.
    public init(
        _ title: String,
        value: Int = 0,
        range: ClosedRange<Int> = 0...100,
        step: Int = 1,
        variant: WinStepperVariant = .compact,
        onChange: ((Int) -> Void)? = nil,
        valueProvider: (() -> Int)? = nil
    ) {
        self.title = title
        self.minimum = range.lowerBound
        self.maximum = max(range.lowerBound, range.upperBound)
        self.step = max(1, step)
        self.variant = variant
        self.value = min(max(value, minimum), maximum)
        self.onChange = onChange
        self.valueProvider = valueProvider
    }
}

/// Stepper visual variants supported by the traditional API.
public enum WinStepperVariant: Sendable, Hashable {
    /// Title/value label with adjacent decrement and increment buttons.
    case compact
    /// Title label with decrement, value, and increment integrated into one row.
    case integratedValue
}
