/// Imperative container that adds uniform inset around child elements.
///
/// This is the Phase II substrate for SwiftUI-style `.padding(...)`.
public final class WinPadding: WinContainer {
    /// Uniform inset in platform pixels.
    public var amount: Double
    /// Ordered child elements.
    public private(set) var children: [WinElement] = []

    /// Creates a padding container.
    public init(amount: Double) {
        self.amount = amount
    }

    /// Appends a child element.
    public func add(_ element: WinElement) {
        children.append(element)
    }
}
