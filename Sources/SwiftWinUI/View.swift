public protocol View {
    func render(into context: RenderContext)
}

public struct RenderContext {
    public let renderer: Renderer

    public init(renderer: Renderer) {
        self.renderer = renderer
    }
}

public protocol Renderer: AnyObject {
    func beginWindow(_ descriptor: WindowDescriptor)
    func endWindow()
    func beginStack(axis: StackAxis, spacing: Double)
    func endStack()
    func text(_ value: String, style: TextStyle)
    func button(_ title: String, action: @escaping () -> Void)
    func spacer()
}

public enum StackAxis: Sendable {
    case horizontal
    case vertical
}

public struct EmptyView: View {
    public init() {}

    public func render(into context: RenderContext) {}
}

public struct AnyView: View {
    private let renderBody: (RenderContext) -> Void

    public init<V: View>(_ view: V) {
        self.renderBody = view.render
    }

    public func render(into context: RenderContext) {
        renderBody(context)
    }
}

@resultBuilder
public enum ViewBuilder {
    public static func buildBlock() -> EmptyView {
        EmptyView()
    }

    public static func buildBlock<V: View>(_ view: V) -> V {
        view
    }

    public static func buildBlock(_ views: AnyView...) -> TupleView {
        TupleView(views)
    }

    public static func buildExpression<V: View>(_ expression: V) -> AnyView {
        AnyView(expression)
    }

    public static func buildOptional(_ component: AnyView?) -> AnyView {
        component ?? AnyView(EmptyView())
    }

    public static func buildEither(first component: AnyView) -> AnyView {
        component
    }

    public static func buildEither(second component: AnyView) -> AnyView {
        component
    }
}

public struct TupleView: View {
    private let children: [AnyView]

    public init(_ children: [AnyView]) {
        self.children = children
    }

    public func render(into context: RenderContext) {
        for child in children {
            child.render(into: context)
        }
    }
}
