/// Determinate progress indicator in the traditional API.
///
/// The current Win32 backend maps this to a common-controls progress bar.
public final class WinProgressView: WinElement {
    /// Optional label shown above the progress bar.
    public var title: String?
    /// Current progress value.
    public var value: Double {
        provider()
    }
    /// Total value that represents completion.
    public var total: Double

    private let provider: () -> Double

    /// Creates a progress view with a fixed value.
    public init(_ title: String? = nil, value: Double, total: Double = 1) {
        self.title = title
        self.total = max(0.0001, total)
        self.provider = { value }
    }

    /// Creates a progress view whose value can be refreshed after state changes.
    public init(_ title: String? = nil, value: @escaping () -> Double, total: Double = 1) {
        self.title = title
        self.total = max(0.0001, total)
        self.provider = value
    }
}
