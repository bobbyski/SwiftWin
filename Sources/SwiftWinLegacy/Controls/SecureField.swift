/// Password-style single-line text field in the traditional API.
///
/// Windows implementation note:
/// This maps to a Win32 `EDIT` child window with `ES_PASSWORD`. The Swift
/// value remains plain text in memory just like most UI toolkit password
/// controls, so future credential helpers should avoid long-lived storage when
/// handling truly sensitive data.
public final class WinSecureField: WinEditableText, WinRefreshableControl {
    /// Prompt shown when the field is empty.
    public var prompt: String
    /// Current plain-text value.
    public var value: String
    /// Closure invoked when native editing changes the value.
    public var onChange: ((String) -> Void)?
    /// Optional source of truth used when external state invalidates the view.
    public var textProvider: (() -> String)?

    /// Creates a secure field.
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
