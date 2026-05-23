/// Single-line editable text field in the traditional API.
///
/// Windows implementation note:
/// This maps to a Win32 `EDIT` child window. The runtime updates `value` from
/// `EN_CHANGE` notifications so imperative code can read the latest value from
/// actions such as button closures.
public final class WinTextField: WinEditableText, WinRefreshableControl {
    /// Prompt shown when the field is empty.
    public var prompt: String
    /// Current text value.
    public var value: String
    /// Closure invoked when native editing changes the value.
    public var onChange: ((String) -> Void)?
    /// Optional source of truth used when external state invalidates the view.
    public var textProvider: (() -> String)?

    /// Creates a text field.
    public init(
        _ prompt: String,
        text: String = "",
        onChange: ((String) -> Void)? = nil,
        textProvider: (() -> String)? = nil
    ) {
        self.prompt = prompt
        self.value = text
        self.onChange = onChange
        self.textProvider = textProvider
    }

    /// Mirrors the current Swift value into the active native control.
    public func refresh() {
        WinControlInvalidation.refresh(self)
    }
}
