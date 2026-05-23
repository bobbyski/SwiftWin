/// Static text element in the traditional API.
public final class WinText: WinTextDisplaying {
    /// Displayed text.
    public var value: String
    /// Text style used by the native runtime.
    public var style: WinTextStyle
    /// Foreground color used when the backend can customize text paint.
    public var foregroundStyle: WinForegroundStyle

    /// Creates text.
    public init(_ value: String, style: WinTextStyle = .body, foregroundStyle: WinForegroundStyle = .primary) {
        self.value = value
        self.style = style
        self.foregroundStyle = foregroundStyle
    }
}

/// Text element whose value can be re-evaluated after state changes.
///
/// This is a narrow bridge toward SwiftUI-style invalidation. It lets the
/// declarative layer refresh dependent text without rebuilding the whole HWND
/// tree yet.
public final class WinDynamicText: WinElement {
    /// Current displayed text.
    public var value: String {
        provider()
    }

    /// Text style used by the native runtime.
    public var style: WinTextStyle
    /// Foreground color used when the backend can customize text paint.
    public var foregroundStyle: WinForegroundStyle

    private let provider: () -> String

    /// Creates dynamic text.
    public init(
        _ provider: @escaping () -> String,
        style: WinTextStyle = .body,
        foregroundStyle: WinForegroundStyle = .primary
    ) {
        self.provider = provider
        self.style = style
        self.foregroundStyle = foregroundStyle
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

/// Semantic foreground colors shared by traditional and declarative text.
///
/// Windows note:
/// GDI's `COLORREF` stores colors as `0x00bbggrr`, so conversion happens in
/// the Win32 platform layer rather than leaking that representation here.
public struct WinForegroundStyle: Sendable, Hashable {
    /// Red channel.
    public var red: UInt8
    /// Green channel.
    public var green: UInt8
    /// Blue channel.
    public var blue: UInt8

    /// Main text color.
    public static let primary = WinForegroundStyle(red: 17, green: 24, blue: 39)
    /// Secondary text color.
    public static let secondary = WinForegroundStyle(red: 83, green: 91, blue: 107)
    /// Accent color used for important labels.
    public static let accent = WinForegroundStyle(red: 37, green: 99, blue: 235)
    /// Destructive/error color.
    public static let destructive = WinForegroundStyle(red: 185, green: 28, blue: 28)

    /// Creates a foreground style from RGB channels.
    public init(red: UInt8, green: UInt8, blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}
