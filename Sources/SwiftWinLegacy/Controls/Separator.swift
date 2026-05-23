/// Axis for a separator line.
public enum WinSeparatorAxis: Sendable {
    /// A horizontal line, typically used inside vertical stacks.
    case horizontal
    /// A vertical line, typically used inside horizontal stacks.
    case vertical
}

/// Imperative separator element.
///
/// This is the Phase II substrate for SwiftUI's `Divider`.
public final class WinSeparator: WinElement {
    /// Separator orientation.
    public var axis: WinSeparatorAxis
    /// Separator color.
    public var color: WinForegroundStyle
    /// Separator thickness in platform pixels.
    public var thickness: Double

    /// Creates a separator.
    public init(axis: WinSeparatorAxis = .horizontal, color: WinForegroundStyle = .secondary, thickness: Double = 1) {
        self.axis = axis
        self.color = color
        self.thickness = thickness
    }
}
