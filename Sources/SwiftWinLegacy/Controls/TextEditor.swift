/// Multi-line editable text control in the traditional API.
///
/// Windows implementation note:
/// This maps to a Win32 multiline `EDIT` child window. The runtime updates
/// `value` from `EN_CHANGE` notifications, just like `WinTextField`, while the
/// control style opts into vertical scrolling and return-key text entry.
public final class WinTextEditor: WinEditableText, WinRefreshableControl {
    /// Prompt describing the editor contents.
    public var prompt: String
    /// Current text value.
    public var value: String
    /// Closure invoked when native editing changes the value.
    public var onChange: ((String) -> Void)?
    /// Optional source of truth used when external state invalidates the view.
    public var textProvider: (() -> String)?

    /// Creates a multi-line text editor.
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
