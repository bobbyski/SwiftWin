/// Imperative container that proposes fixed dimensions to child elements.
///
/// This is the Phase II substrate for SwiftUI-style `.frame(width:height:)`.
public final class WinFrame: WinContainer {
    /// Optional fixed width in platform pixels.
    public var width: Double?
    /// Optional fixed height in platform pixels.
    public var height: Double?
    /// Ordered child elements.
    public private(set) var children: [WinElement] = []

    /// Creates a fixed-size frame container.
    public init(width: Double?, height: Double?) {
        self.width = width
        self.height = height
    }

    /// Appends a child element.
    public func add(_ element: WinElement) {
        children.append(element)
    }
}
