/// Clickable external link in the traditional API.
///
/// Windows implementation note:
/// This maps to a lightweight owner-drawn clickable control. Activation is
/// routed through the Windows shell, so the user's default browser or protocol
/// handler owns the final navigation.
public final class WinLink: WinElement {
    /// Text shown for the link.
    public var title: String
    /// Destination URL or shell protocol string.
    public var destination: String

    /// Creates a link.
    public init(_ title: String, destination: String) {
        self.title = title
        self.destination = destination
    }
}
