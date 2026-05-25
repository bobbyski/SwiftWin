/// Accessibility metadata carried by SwiftWinLegacy controls.
///
/// Implementation note:
/// This is deliberately platform-neutral. The Win32 backend stores it beside
/// HWND control IDs today; a later UI Automation bridge can translate it into
/// Windows automation properties without changing app code.
public struct WinAccessibilityMetadata: Sendable, Hashable {
    /// Human-readable label for assistive technologies.
    public var label: String?
    /// Semantic role for the element.
    public var role: WinAccessibilityRole?
    /// Current accessible value, when different from the visible label.
    public var value: String?
    /// Extra help text or usage hint.
    public var hint: String?

    /// Creates metadata with any subset of supported accessibility fields.
    public init(
        label: String? = nil,
        role: WinAccessibilityRole? = nil,
        value: String? = nil,
        hint: String? = nil
    ) {
        self.label = label
        self.role = role
        self.value = value
        self.hint = hint
    }

    /// Merges another metadata scope over this one.
    public func merging(_ other: WinAccessibilityMetadata) -> WinAccessibilityMetadata {
        WinAccessibilityMetadata(
            label: other.label ?? label,
            role: other.role ?? role,
            value: other.value ?? value,
            hint: other.hint ?? hint
        )
    }
}

/// Platform-neutral accessibility role.
public enum WinAccessibilityRole: Sendable, Hashable {
    /// Static text or label.
    case text
    /// Push button or command.
    case button
    /// Editable text field.
    case textField
    /// Boolean checkbox/toggle.
    case toggle
    /// Single-selection option group.
    case picker
    /// Slider/range control.
    case slider
    /// Stepper/range increment control.
    case stepper
    /// Progress indicator.
    case progress
    /// External link.
    case link
    /// Color picker.
    case colorPicker
    /// Date picker.
    case datePicker
}

/// Imperative container that applies accessibility metadata to child controls.
public final class WinAccessibility: WinAccessibilityProviding {
    /// Metadata applied to children.
    public var accessibility: WinAccessibilityMetadata
    /// Ordered child elements.
    public private(set) var children: [WinElement] = []

    /// Creates an accessibility metadata scope.
    public init(_ accessibility: WinAccessibilityMetadata) {
        self.accessibility = accessibility
    }

    /// Appends a child element.
    public func add(_ element: WinElement) {
        children.append(element)
    }
}
