/// Static text in the declarative SwiftWinUI layer.
///
/// This is the SwiftUI-compatible wrapper that currently maps to
/// `SwiftWinLegacy.WinText` on Windows.
public struct Text: View {
    private let value: String
    private let style: TextStyle

    /// Creates static text.
    public init(_ value: String, style: TextStyle = .body) {
        self.value = value
        self.style = style
    }

    /// Emits a semantic text operation to the renderer.
    public func render(into context: RenderContext) {
        context.renderer.text(value, style: style)
    }
}

/// Font description for `Text`.
///
/// This is intentionally small while we move toward SwiftUI-compatible `.font`
/// modifiers and semantic text styles.
public struct TextStyle: Sendable, Hashable {
    /// Font size in prototype points/pixels.
    public var size: Double
    /// Font weight.
    public var weight: FontWeight

    /// Large title text.
    public static let title = TextStyle(size: 24, weight: .semibold)
    /// Default body text.
    public static let body = TextStyle(size: 14, weight: .regular)
    /// Small caption text.
    public static let caption = TextStyle(size: 12, weight: .regular)

    /// Creates a text style.
    public init(size: Double, weight: FontWeight = .regular) {
        self.size = size
        self.weight = weight
    }
}

/// Supported font weights.
public enum FontWeight: Sendable, Hashable {
    /// Normal text weight.
    case regular
    /// Medium emphasis.
    case semibold
    /// Strong emphasis.
    case bold
}
