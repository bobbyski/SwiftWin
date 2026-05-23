/// Checkbox-style boolean control in the traditional API.
public final class WinToggle: WinBooleanControl, WinRefreshableControl {
    /// Text shown next to the checkbox.
    public var title: String
    /// Current boolean value.
    public var isOn: Bool
    /// Closure invoked when native editing changes the value.
    public var onChange: ((Bool) -> Void)?
    /// Optional source of truth used when external state invalidates the view.
    public var valueProvider: (() -> Bool)?

    /// Creates a toggle.
    public init(
        _ title: String,
        isOn: Bool = false,
        onChange: ((Bool) -> Void)? = nil,
        valueProvider: (() -> Bool)? = nil
    ) {
        self.title = title
        self.isOn = isOn
        self.onChange = onChange
        self.valueProvider = valueProvider
    }

    /// Mirrors the current Swift value into the active native control.
    public func refresh() {
        WinControlInvalidation.refresh(self)
    }
}
