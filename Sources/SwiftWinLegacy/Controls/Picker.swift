/// Segmented radio-button picker in the traditional API.
public final class WinPicker: WinSelectionControl, WinRefreshableControl {
    /// Label describing the selection.
    public var title: String
    /// Available option labels.
    public var options: [String]
    /// Current selected option index.
    public var selectedIndex: Int
    /// Closure invoked when native editing changes the selected index.
    public var onChange: ((Int) -> Void)?
    /// Optional source of truth used when external state invalidates the view.
    public var selectionProvider: (() -> Int)?

    /// Creates a picker.
    public init(
        _ title: String,
        options: [String],
        selectedIndex: Int = 0,
        onChange: ((Int) -> Void)? = nil,
        selectionProvider: (() -> Int)? = nil
    ) {
        self.title = title
        self.options = options
        self.selectedIndex = min(max(selectedIndex, 0), max(0, options.count - 1))
        self.onChange = onChange
        self.selectionProvider = selectionProvider
    }

    /// Mirrors the current Swift value into the active native control.
    public func refresh() {
        WinControlInvalidation.refresh(self)
    }
}
