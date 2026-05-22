/// A declarative SwiftWinUI view.
///
/// This protocol intentionally mirrors SwiftUI's `View` role. Custom views can
/// describe their content with `body`, while primitive controls can implement
/// `render(into:)` directly as renderer-backed leaves.
public protocol View {
    /// The view content produced by this view.
    associatedtype Body: View = Never

    /// Rebuildable declarative content for this view.
    ///
    /// Compatibility note:
    /// User-authored multi-child bodies should annotate their implementation
    /// with `@ViewBuilder` until this toolchain can carry the builder cleanly
    /// from the protocol requirement to all conformers.
    var body: Body { get }

    /// Emits this view into the current renderer.
    func render(into context: RenderContext)
}

public extension View where Body: View {
    /// Renders this view by rendering its declarative body.
    ///
    /// Implementation note:
    /// This is the compatibility hook behind SwiftUI-shaped custom views. The
    /// body can be rebuilt freely; persistent identity and invalidation will be
    /// layered in later.
    func render(into context: RenderContext) {
        body.render(into: context)
    }
}

public extension View where Body == Never {
    /// Primitive views do not expose a body.
    var body: Never {
        fatalError("Primitive SwiftWinUI views do not have a body.")
    }
}

extension Never: View {
    public typealias Body = Never

    public var body: Never {
        fatalError("Never has no view body.")
    }

    public func render(into context: RenderContext) {
        fatalError("Never cannot render.")
    }
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
    /// Called when declarative state changes and a future render pass is needed.
    func invalidate()
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
    /// Renders text that can be re-evaluated after state changes.
    func dynamicText(_ value: @escaping () -> String, style: TextStyle)
    /// Renders a button and stores its action for native event dispatch.
    func button(_ title: String, style: ButtonStyle, action: @escaping () -> Void)
    /// Renders a single-line editable text field.
    func textField(_ prompt: String, text: String, onChange: ((String) -> Void)?)
    /// Renders a boolean toggle.
    func toggle(_ title: String, isOn: Bool, onChange: ((Bool) -> Void)?)
    /// Renders a segmented picker.
    func picker(_ title: String, options: [String], selectedIndex: Int, onChange: ((Int) -> Void)?)
    /// Renders an integer slider.
    func slider(_ title: String, value: Int, range: ClosedRange<Int>, onChange: ((Int) -> Void)?)
    /// Renders a spacer.
    func spacer()
}

public extension Renderer {
    /// Default invalidation hook for renderers that do not yet support rebuilds.
    func invalidate() {}

    /// Default dynamic text implementation for renderers without invalidation.
    func dynamicText(_ value: @escaping () -> String, style: TextStyle) {
        text(value(), style: style)
    }
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
