/// Accessibility metadata for SwiftWinUI views.
///
/// This is intentionally small and SwiftUI-shaped. The Windows backend records
/// the metadata today and will later translate it into UI Automation
/// properties.
public struct AccessibilityMetadata: Sendable, Hashable {
    /// Human-readable label for assistive technologies.
    public var label: String?
    /// Semantic role for the view.
    public var role: AccessibilityRole?
    /// Current accessible value.
    public var value: String?
    /// Extra help text or usage hint.
    public var hint: String?

    /// Creates metadata with any subset of supported accessibility fields.
    public init(
        label: String? = nil,
        role: AccessibilityRole? = nil,
        value: String? = nil,
        hint: String? = nil
    ) {
        self.label = label
        self.role = role
        self.value = value
        self.hint = hint
    }
}

/// Platform-neutral accessibility role.
public enum AccessibilityRole: Sendable, Hashable {
    case text
    case button
    case textField
    case toggle
    case picker
    case slider
    case stepper
    case progress
    case link
    case colorPicker
    case datePicker
}

/// A view that applies accessibility metadata to compatible children.
public struct AccessibilityModifier<Content: View>: View {
    private let metadata: AccessibilityMetadata
    private let content: Content

    /// Creates an accessibility metadata wrapper.
    public init(metadata: AccessibilityMetadata, content: Content) {
        self.metadata = metadata
        self.content = content
    }

    /// Emits accessibility begin/end calls around the content.
    public func render(into context: RenderContext) {
        context.renderer.beginAccessibility(metadata)
        content.render(into: context)
        context.renderer.endAccessibility()
    }
}

public extension View {
    /// Supplies an accessibility label.
    func accessibilityLabel(_ label: String) -> AccessibilityModifier<Self> {
        AccessibilityModifier(metadata: AccessibilityMetadata(label: label), content: self)
    }

    /// Supplies an accessibility value.
    func accessibilityValue(_ value: String) -> AccessibilityModifier<Self> {
        AccessibilityModifier(metadata: AccessibilityMetadata(value: value), content: self)
    }

    /// Supplies an accessibility role.
    func accessibilityRole(_ role: AccessibilityRole) -> AccessibilityModifier<Self> {
        AccessibilityModifier(metadata: AccessibilityMetadata(role: role), content: self)
    }

    /// Supplies an accessibility hint.
    func accessibilityHint(_ hint: String) -> AccessibilityModifier<Self> {
        AccessibilityModifier(metadata: AccessibilityMetadata(hint: hint), content: self)
    }
}
