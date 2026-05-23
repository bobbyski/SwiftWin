/// Imperative container that paints a solid border around child elements.
///
/// This is the Phase II substrate for SwiftUI-style `.border(...)`.
public final class WinBorder: WinContainer {
    /// Border color.
    public var color: WinForegroundStyle
    /// Border line width in platform pixels.
    public var width: Double
    /// Ordered child elements.
    public private(set) var children: [WinElement] = []

    /// Creates a border container.
    public init(color: WinForegroundStyle, width: Double = 1) {
        self.color = color
        self.width = width
    }

    /// Appends a child element.
    public func add(_ element: WinElement) {
        children.append(element)
    }
}
