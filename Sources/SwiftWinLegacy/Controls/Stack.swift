/// Axis for traditional stack layout.
public enum WinAxis: Sendable {
    /// Children flow left to right.
    case horizontal
    /// Children flow top to bottom.
    case vertical
}

/// Imperative stack container.
///
/// `WinStack` currently maps to simple direct placement in the Win32 runtime.
/// It is intended to become the shared layout primitive that SwiftWinUI stacks
/// can wrap.
public final class WinStack: WinContainer {
    /// Stack direction.
    public var axis: WinAxis
    /// Spacing between child elements.
    public var spacing: Double
    /// Ordered child elements.
    public private(set) var children: [WinElement] = []

    /// Creates a stack.
    public init(axis: WinAxis, spacing: Double = 8) {
        self.axis = axis
        self.spacing = spacing
    }

    /// Appends a child element.
    public func add(_ element: WinElement) {
        children.append(element)
    }
}
