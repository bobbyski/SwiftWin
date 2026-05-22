/// Imperative container that carries enabled/disabled state to child controls.
///
/// This is the Phase II substrate for SwiftUI-style `.disabled(...)`.
public final class WinDisabled: WinContainer {
    /// Whether child interactive controls should be disabled.
    public var isDisabled: Bool
    /// Ordered child elements.
    public private(set) var children: [WinElement] = []

    /// Creates a disabled-state container.
    public init(isDisabled: Bool) {
        self.isDisabled = isDisabled
    }

    /// Appends a child element.
    public func add(_ element: WinElement) {
        children.append(element)
    }
}
