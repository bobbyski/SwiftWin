/// Imperative container that attaches hover callbacks to child controls.
///
/// Implementation note:
/// This intentionally behaves like a scoped modifier rather than a visual
/// element. The Win32 backend registers the callback on controls emitted inside
/// this container when those controls already participate in mouse tracking.
public final class WinHover: WinHoverHandling {
    /// Closure invoked with `true` on mouse enter and `false` on mouse exit.
    public var onHover: ((Bool) -> Void)
    /// Ordered child elements.
    public private(set) var children: [WinElement] = []

    /// Creates a hover callback scope.
    public init(onHover: @escaping (Bool) -> Void) {
        self.onHover = onHover
    }

    /// Appends a child element.
    public func add(_ element: WinElement) {
        children.append(element)
    }
}
