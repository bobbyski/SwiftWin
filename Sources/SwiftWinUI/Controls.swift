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

/// Clickable button in the declarative SwiftWinUI layer.
///
/// The current Windows path adapts this to `SwiftWinLegacy.WinButton`.
public struct Button: View {
    private let title: String
    private let style: ButtonStyle
    private let action: () -> Void

    /// Creates a button.
    ///
    /// - Parameters:
    ///   - title: Text shown on the button.
    ///   - style: Visual role for the button.
    ///   - action: Closure invoked when native command routing reports a click.
    public init(
        _ title: String,
        style: ButtonStyle = .secondary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.action = action
    }

    /// Emits a semantic button operation to the renderer.
    public func render(into context: RenderContext) {
        context.renderer.button(title, style: style, action: action)
    }
}

/// Button visual role.
public enum ButtonStyle: Sendable, Hashable {
    /// Main action button.
    case primary
    /// Standard secondary action button.
    case secondary
}

/// Inserts space in the current layout.
///
/// Current behavior is fixed spacing in the legacy renderer. A flexible
/// SwiftUI-compatible spacer is planned once the layout engine exists.
public struct Spacer: View {
    /// Creates a spacer.
    public init() {}

    /// Emits a spacer operation.
    public func render(into context: RenderContext) {
        context.renderer.spacer()
    }
}

/// Vertical stack layout container.
public struct VStack<Content: View>: View {
    private let spacing: Double
    private let content: Content

    /// Creates a vertical stack.
    public init(spacing: Double = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    /// Emits stack begin/end calls around the child content.
    public func render(into context: RenderContext) {
        context.renderer.beginStack(axis: .vertical, spacing: spacing)
        content.render(into: context)
        context.renderer.endStack()
    }
}

/// Horizontal stack layout container.
public struct HStack<Content: View>: View {
    private let spacing: Double
    private let content: Content

    /// Creates a horizontal stack.
    public init(spacing: Double = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    /// Emits stack begin/end calls around the child content.
    public func render(into context: RenderContext) {
        context.renderer.beginStack(axis: .horizontal, spacing: spacing)
        content.render(into: context)
        context.renderer.endStack()
    }
}
