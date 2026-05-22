public struct Text: View {
    private let value: String
    private let style: TextStyle

    public init(_ value: String, style: TextStyle = .body) {
        self.value = value
        self.style = style
    }

    public func render(into context: RenderContext) {
        context.renderer.text(value, style: style)
    }
}

public struct TextStyle: Sendable, Equatable {
    public var size: Double
    public var weight: FontWeight

    public static let title = TextStyle(size: 24, weight: .semibold)
    public static let body = TextStyle(size: 14, weight: .regular)
    public static let caption = TextStyle(size: 12, weight: .regular)

    public init(size: Double, weight: FontWeight = .regular) {
        self.size = size
        self.weight = weight
    }
}

public enum FontWeight: Sendable, Equatable {
    case regular
    case semibold
    case bold
}

public struct Button: View {
    private let title: String
    private let action: () -> Void

    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public func render(into context: RenderContext) {
        context.renderer.button(title, action: action)
    }
}

public struct Spacer: View {
    public init() {}

    public func render(into context: RenderContext) {
        context.renderer.spacer()
    }
}

public struct VStack<Content: View>: View {
    private let spacing: Double
    private let content: Content

    public init(spacing: Double = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public func render(into context: RenderContext) {
        context.renderer.beginStack(axis: .vertical, spacing: spacing)
        content.render(into: context)
        context.renderer.endStack()
    }
}

public struct HStack<Content: View>: View {
    private let spacing: Double
    private let content: Content

    public init(spacing: Double = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public func render(into context: RenderContext) {
        context.renderer.beginStack(axis: .horizontal, spacing: spacing)
        content.render(into: context)
        context.renderer.endStack()
    }
}
