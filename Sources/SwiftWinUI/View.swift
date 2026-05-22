/// A declarative SwiftWinUI view.
///
/// This protocol intentionally mirrors SwiftUI's `View` role, but the current
/// implementation renders immediately into a `Renderer` rather than building a
/// fully diffable persistent tree. Moving toward a normalized tree is planned.
public protocol View {
    /// Emits this view into the current renderer.
    func render(into context: RenderContext)
}

/// Rendering context passed through a declarative view tree.
public struct RenderContext {
    /// The backend receiving normalized view operations.
    public let renderer: Renderer

    /// Creates a render context.
    public init(renderer: Renderer) {
        self.renderer = renderer
    }
}

/// Backend contract used by SwiftWinUI views.
///
/// `Renderer` is deliberately small and semantic. The SwiftUI-compatible layer
/// should describe intent here; native details belong in renderer
/// implementations or the `SwiftWinLegacy` runtime.
public protocol Renderer: AnyObject {
    /// Begins rendering a window.
    func beginWindow(_ descriptor: WindowDescriptor)
    /// Ends rendering a window and usually starts/shows it.
    func endWindow()
    /// Begins a stack layout container.
    func beginStack(axis: StackAxis, spacing: Double)
    /// Ends the current stack layout container.
    func endStack()
    /// Renders static text.
    func text(_ value: String, style: TextStyle)
    /// Renders a button and stores its action for native event dispatch.
    func button(_ title: String, style: ButtonStyle, action: @escaping () -> Void)
    /// Renders a single-line editable text field.
    func textField(_ prompt: String, text: String, onChange: ((String) -> Void)?)
    /// Renders a spacer.
    func spacer()
}

/// Axis for stack layout.
public enum StackAxis: Sendable {
    /// Children are placed left to right.
    case horizontal
    /// Children are placed top to bottom.
    case vertical
}

/// A view with no visual output.
public struct EmptyView: View {
    /// Creates an empty view.
    public init() {}

    /// Intentionally emits no renderer calls.
    public func render(into context: RenderContext) {}
}

/// Type-erased view wrapper used by `ViewBuilder`.
///
/// This is a small compatibility bridge while the framework grows more
/// SwiftUI-like result-builder support.
public struct AnyView: View {
    private let renderBody: (RenderContext) -> Void

    /// Wraps any concrete view.
    public init<V: View>(_ view: V) {
        self.renderBody = view.render
    }

    /// Forwards rendering to the wrapped view.
    public func render(into context: RenderContext) {
        renderBody(context)
    }
}

/// Result builder for declarative view content.
///
/// Current support covers the forms used by the demo and simple conditional
/// content. `ForEach`, `Group`, richer tuple overloads, and modifier support
/// are planned for SwiftUI compatibility.
@resultBuilder
public enum ViewBuilder {
    /// Builds empty content.
    public static func buildBlock() -> EmptyView {
        EmptyView()
    }

    /// Builds a single concrete view without type erasure.
    public static func buildBlock<V: View>(_ view: V) -> V {
        view
    }

    /// Builds multiple type-erased child views.
    public static func buildBlock(_ views: AnyView...) -> TupleView {
        TupleView(views)
    }

    /// Erases builder expressions to `AnyView`.
    public static func buildExpression<V: View>(_ expression: V) -> AnyView {
        AnyView(expression)
    }

    /// Builds optional content.
    public static func buildOptional(_ component: AnyView?) -> AnyView {
        component ?? AnyView(EmptyView())
    }

    /// Builds the first branch of conditional content.
    public static func buildEither(first component: AnyView) -> AnyView {
        component
    }

    /// Builds the second branch of conditional content.
    public static func buildEither(second component: AnyView) -> AnyView {
        component
    }
}

/// A simple ordered collection of child views.
public struct TupleView: View {
    private let children: [AnyView]

    /// Creates a tuple view from already-erased children.
    public init(_ children: [AnyView]) {
        self.children = children
    }

    /// Renders children in declaration order.
    public func render(into context: RenderContext) {
        for child in children {
            child.render(into: context)
        }
    }
}
