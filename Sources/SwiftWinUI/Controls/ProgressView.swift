/// Determinate progress indicator in the declarative SwiftWinUI layer.
///
/// This is an early SwiftUI-compatible surface for `ProgressView(value:total:)`.
/// Indeterminate progress and progress styles remain planned.
public struct ProgressView: View {
    private let title: String?
    private let value: () -> Double
    private let total: Double

    /// Creates a determinate progress view.
    public init(_ title: String? = nil, value: @autoclosure @escaping () -> Double, total: Double = 1) {
        self.title = title
        self.value = value
        self.total = max(0.0001, total)
    }

    /// Creates a determinate progress view from an integer value.
    public init(_ title: String? = nil, value: @autoclosure @escaping () -> Int, total: Int = 100) {
        self.title = title
        self.value = { Double(value()) }
        self.total = max(0.0001, Double(total))
    }

    /// Emits a semantic progress operation to the renderer.
    public func render(into context: RenderContext) {
        context.renderer.progressView(title, value: value, total: total)
    }
}
