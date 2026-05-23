/// Integer range slider in the traditional API.
///
/// The current Win32 backend maps this to a common-controls trackbar and keeps
/// the visible value label synchronized while native scroll messages arrive.
public final class WinSlider: WinRangeControl, WinRefreshableControl {
    /// Label describing the value.
    public var title: String
    /// Current value.
    public var value: Int
    /// Minimum allowed value.
    public var minimum: Int
    /// Maximum allowed value.
    public var maximum: Int
    /// Closure invoked when native editing changes the value.
    public var onChange: ((Int) -> Void)?
    /// Optional source of truth used when external state invalidates the view.
    public var valueProvider: (() -> Int)?

    /// Creates a slider.
    public init(
        _ title: String,
        value: Int = 0,
        range: ClosedRange<Int> = 0...100,
        onChange: ((Int) -> Void)? = nil,
        valueProvider: (() -> Int)? = nil
    ) {
        self.title = title
        self.minimum = range.lowerBound
        self.maximum = max(range.lowerBound, range.upperBound)
        self.value = min(max(value, minimum), maximum)
        self.onChange = onChange
        self.valueProvider = valueProvider
    }

    /// Mirrors the current Swift value into the active native control.
    public func refresh() {
        WinControlInvalidation.refresh(self)
    }
}
