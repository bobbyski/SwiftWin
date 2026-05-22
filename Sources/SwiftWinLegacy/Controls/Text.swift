/// Static text element in the traditional API.
public final class WinText: WinTextDisplaying {
    /// Displayed text.
    public var value: String
    /// Text style used by the native runtime.
    public var style: WinTextStyle

    /// Creates text.
    public init(_ value: String, style: WinTextStyle = .body) {
        self.value = value
        self.style = style
    }
}

/// Font description for `WinText`.
public struct WinTextStyle: Sendable, Hashable {
    /// Font size in prototype points/pixels.
    public var size: Double
    /// Font weight.
    public var weight: WinFontWeight

    /// Large title text.
    public static let title = WinTextStyle(size: 24, weight: .semibold)
    /// Default body text.
    public static let body = WinTextStyle(size: 14, weight: .regular)
    /// Small caption text.
    public static let caption = WinTextStyle(size: 12, weight: .regular)

    /// Creates a text style.
    public init(size: Double, weight: WinFontWeight = .regular) {
        self.size = size
        self.weight = weight
    }
}

/// Supported font weights.
public enum WinFontWeight: Sendable, Hashable {
    /// Normal text weight.
    case regular
    /// Medium emphasis.
    case semibold
    /// Strong emphasis.
    case bold
}
