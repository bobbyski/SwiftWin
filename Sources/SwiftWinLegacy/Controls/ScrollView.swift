/// Imperative vertical scroll container.
///
/// Implementation note:
/// This is the first explicit scroll container. It gives the runtime a scoped
/// viewport and child-control list instead of relying only on whole-window
/// scrolling. Full nested scroll views and native scrollbars remain future
/// layout-engine work.
public final class WinScrollView: WinContainer {
    /// Optional viewport width.
    public var width: Double?
    /// Optional viewport height.
    public var height: Double?
    /// Ordered child elements.
    public private(set) var children: [WinElement] = []

    /// Creates a vertical scroll view.
    public init(width: Double? = nil, height: Double? = nil) {
        self.width = width
        self.height = height
    }

    /// Appends a child element.
    public func add(_ element: WinElement) {
        children.append(element)
    }
}
