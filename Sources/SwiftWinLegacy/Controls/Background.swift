/// Imperative container that paints a solid background behind child elements.
///
/// This is the Phase II substrate for SwiftUI-style `.background(...)`.
public final class WinBackground: WinContainer {
    /// Solid color used for the background panel.
    public var color: WinForegroundStyle
    /// Corner radius in platform pixels.
    public var cornerRadius: Double
    /// Ordered child elements.
    public private(set) var children: [WinElement] = []

    /// Creates a background container.
    public init(color: WinForegroundStyle, cornerRadius: Double = 0) {
        self.color = color
        self.cornerRadius = cornerRadius
    }

    /// Appends a child element.
    public func add(_ element: WinElement) {
        children.append(element)
    }
}
