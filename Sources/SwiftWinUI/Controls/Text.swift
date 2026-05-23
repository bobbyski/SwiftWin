/// Static text in the declarative SwiftWinUI layer.
///
/// This is the SwiftUI-compatible wrapper that currently maps to
/// `SwiftWinLegacy.WinText` on Windows.
public struct Text: View {
    private let value: () -> String
    private let style: TextStyle?

    /// Creates static text.
    public init(_ value: @autoclosure @escaping () -> String, style: TextStyle? = nil) {
        self.value = value
        self.style = style
    }

    /// Emits a semantic text operation to the renderer.
    public func render(into context: RenderContext) {
        context.renderer.dynamicText(
            value,
            style: context.renderer.resolveTextStyle(style),
            foregroundStyle: context.renderer.resolveForegroundStyle()
        )
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

/// SwiftUI-compatible name for text style values used by `.font(...)`.
public typealias Font = TextStyle

/// Semantic foreground style for text and future shape rendering.
///
/// This mirrors the shape of SwiftUI's `.foregroundStyle(...)` without trying
/// to model every SwiftUI `ShapeStyle` form yet.
public struct ForegroundStyle: Sendable, Hashable {
    /// Red channel.
    public var red: UInt8
    /// Green channel.
    public var green: UInt8
    /// Blue channel.
    public var blue: UInt8

    /// Main text color.
    public static let primary = ForegroundStyle(red: 17, green: 24, blue: 39)
    /// Secondary text color.
    public static let secondary = ForegroundStyle(red: 83, green: 91, blue: 107)
    /// Accent color for important labels.
    public static let accent = ForegroundStyle(red: 37, green: 99, blue: 235)
    /// Destructive/error color.
    public static let destructive = ForegroundStyle(red: 185, green: 28, blue: 28)

    /// Creates a foreground style from RGB channels.
    public init(red: UInt8, green: UInt8, blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

/// SwiftUI-compatible color spelling for the current semantic foreground model.
public typealias Color = ForegroundStyle
