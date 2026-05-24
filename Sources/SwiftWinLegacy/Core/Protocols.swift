/// Marker protocol for imperative UI elements.
///
/// The first version uses class-based elements because the traditional API is
/// expected to gain identity, mutation, and event hooks over time.
public protocol WinElement: AnyObject {}

/// Protocol for objects that can run a traditional SwiftWin window.
///
/// Keeping this as a protocol lets tests, future hosted runtimes, or alternate
/// app shells provide their own runner without changing `WinApplication` users.
public protocol WinApplicationRunning: AnyObject {
    /// Runs a window until the backing runtime exits.
    func run(_ window: WinWindow)
}

/// Protocol for elements that own an ordered list of child elements.
///
/// Containers expose their children read-only to callers while still providing
/// an explicit mutation method. This keeps the public API simple and leaves
/// room for future validation when layout rules become more complex.
public protocol WinContainer: WinElement {
    /// Ordered child elements.
    var children: [WinElement] { get }
    /// Appends a child element.
    func add(_ element: WinElement)
}

/// Protocol for elements that display mutable text.
///
/// Custom controls can conform to this when they want to participate in shared
/// text styling, accessibility, or future data binding code.
public protocol WinTextDisplaying: WinElement {
    /// Displayed text.
    var value: String { get set }
    /// Text style used by the native runtime.
    var style: WinTextStyle { get set }
    /// Semantic foreground color used by backends that support custom text paint.
    var foregroundStyle: WinForegroundStyle { get set }
}

/// Protocol for editable text controls.
///
/// This is the first Milestone 2 form contract. It gives the imperative layer a
/// typed way to observe native text changes before the declarative layer grows
/// full `Binding` support.
public protocol WinEditableText: WinElement {
    /// Prompt shown when the control is empty, where the platform supports it.
    var prompt: String { get set }
    /// Current text value.
    var value: String { get set }
    /// Closure invoked after native editing changes the value.
    var onChange: ((String) -> Void)? { get set }
}

/// Protocol for controls with a visible title.
public protocol WinTitledControl: WinElement {
    /// Text shown by the control.
    var title: String { get set }
}

/// Protocol for controls that invoke an action.
public protocol WinActionControl: WinElement {
    /// Closure invoked by native event routing.
    var action: () -> Void { get set }
}

/// Protocol for button-like controls.
///
/// `WinButton` is the first implementation, but this keeps room for custom
/// command buttons, toolbar buttons, or owner-provided button controls.
public protocol WinButtonDisplaying: WinTitledControl, WinActionControl {
    /// Visual role for the button.
    var style: WinButtonStyle { get set }
}

/// Protocol for controls that expose an on/off value.
public protocol WinBooleanControl: WinElement {
    /// Text shown next to the control.
    var title: String { get set }
    /// Current boolean value.
    var isOn: Bool { get set }
    /// Closure invoked after native editing changes the value.
    var onChange: ((Bool) -> Void)? { get set }
}

/// Protocol for controls that select one option from a fixed list.
public protocol WinSelectionControl: WinElement {
    /// Label describing the selection.
    var title: String { get set }
    /// Available option labels.
    var options: [String] { get set }
    /// Current selected option index.
    var selectedIndex: Int { get set }
    /// Closure invoked after native editing changes the selected index.
    var onChange: ((Int) -> Void)? { get set }
}

/// Protocol for controls that edit an integer value inside a range.
public protocol WinRangeControl: WinElement {
    /// Label describing the value.
    var title: String { get set }
    /// Current value.
    var value: Int { get set }
    /// Minimum allowed value.
    var minimum: Int { get set }
    /// Maximum allowed value.
    var maximum: Int { get set }
    /// Closure invoked after native editing changes the value.
    var onChange: ((Int) -> Void)? { get set }
}

/// Protocol for controls that edit an RGB color value.
public protocol WinColorControl: WinElement {
    /// Label describing the color.
    var title: String { get set }
    /// Current RGB color.
    var color: WinForegroundStyle { get set }
    /// Closure invoked after native interaction changes the color.
    var onChange: ((WinForegroundStyle) -> Void)? { get set }
}

/// Protocol for controls that edit a calendar date value.
public protocol WinDateControl: WinElement {
    /// Label describing the selected date.
    var title: String { get set }
    /// Current selected date.
    var date: WinDate { get set }
    /// Closure invoked after native interaction changes the date.
    var onChange: ((WinDate) -> Void)? { get set }
}

/// Protocol for controls whose native HWND can be refreshed from Swift values.
///
/// This is intentionally small: the element remains the source of truth, while
/// the active runtime decides how to mirror that value into native controls.
/// Custom controls can conform later once they have renderer support.
public protocol WinRefreshableControl: WinElement {
    /// Requests that the active runtime refresh the control's native peer.
    func refresh()
}
