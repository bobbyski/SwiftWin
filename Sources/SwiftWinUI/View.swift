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
    /// Begins a uniform padding container.
    func beginPadding(_ amount: Double)
    /// Ends the current padding container.
    func endPadding()
    /// Begins a fixed-size layout proposal.
    func beginFrame(width: Double?, height: Double?)
    /// Ends the current fixed-size layout proposal.
    func endFrame()
    /// Begins a disabled-state scope.
    func beginDisabled(_ isDisabled: Bool)
    /// Ends the current disabled-state scope.
    func endDisabled()
    /// Begins a hover callback scope.
    func beginHover(_ onHover: @escaping (Bool) -> Void)
    /// Ends the current hover callback scope.
    func endHover()
    /// Begins a text font scope.
    func beginFont(_ style: TextStyle)
    /// Ends the current text font scope.
    func endFont()
    /// Resolves an explicit or inherited text style.
    func resolveTextStyle(_ style: TextStyle?) -> TextStyle
    /// Begins a foreground style scope.
    func beginForegroundStyle(_ style: ForegroundStyle)
    /// Ends the current foreground style scope.
    func endForegroundStyle()
    /// Resolves inherited foreground style.
    func resolveForegroundStyle() -> ForegroundStyle
    /// Begins a background color scope.
    func beginBackground(_ style: Color)
    /// Ends the current background color scope.
    func endBackground()
    /// Begins a solid border scope.
    func beginBorder(_ color: Color, width: Double)
    /// Ends the current solid border scope.
    func endBorder()
    /// Begins a corner-radius scope for compatible decoration modifiers.
    func beginCornerRadius(_ radius: Double)
    /// Ends the current corner-radius scope.
    func endCornerRadius()
    /// Resolves the current inherited corner radius.
    func resolveCornerRadius() -> Double
    /// Renders static text.
    func text(_ value: String, style: TextStyle, foregroundStyle: ForegroundStyle)
    /// Renders text that can be re-evaluated after state changes.
    func dynamicText(_ value: @escaping () -> String, style: TextStyle, foregroundStyle: ForegroundStyle)
    /// Renders a button and stores its action for native event dispatch.
    func button(_ title: String, style: ButtonStyle, role: ButtonRole?, action: @escaping () -> Void)
    /// Renders an external link.
    func link(_ title: String, destination: String)
    /// Renders a single-line editable text field.
    func textField(_ prompt: String, text: String, textProvider: (() -> String)?, onChange: ((String) -> Void)?)
    /// Renders a password-style single-line editable text field.
    func secureField(_ prompt: String, text: String, textProvider: (() -> String)?, onChange: ((String) -> Void)?)
    /// Renders a multi-line editable text area.
    func textEditor(_ prompt: String, text: String, textProvider: (() -> String)?, onChange: ((String) -> Void)?)
    /// Renders a boolean toggle.
    func toggle(_ title: String, isOn: Bool, valueProvider: (() -> Bool)?, onChange: ((Bool) -> Void)?)
    /// Renders a segmented picker.
    func picker(_ title: String, options: [String], selectedIndex: Int, selectionProvider: (() -> Int)?, onChange: ((Int) -> Void)?)
    /// Renders an integer slider.
    func slider(_ title: String, value: Int, range: ClosedRange<Int>, valueProvider: (() -> Int)?, onChange: ((Int) -> Void)?)
    /// Renders an integer stepper.
    func stepper(
        _ title: String,
        value: Int,
        range: ClosedRange<Int>,
        step: Int,
        variant: StepperVariant,
        valueProvider: (() -> Int)?,
        onChange: ((Int) -> Void)?
    )
    /// Renders a color picker.
    func colorPicker(_ title: String, color: Color, colorProvider: (() -> Color)?, onChange: ((Color) -> Void)?)
    /// Renders a date picker.
    func datePicker(_ title: String, date: CalendarDate, dateProvider: (() -> CalendarDate)?, onChange: ((CalendarDate) -> Void)?)
    /// Renders a determinate progress indicator.
    func progressView(_ title: String?, value: @escaping () -> Double, total: Double)
    /// Renders a spacer.
    func spacer()
    /// Renders a separator line.
    func divider()
}

public extension Renderer {
    /// Default invalidation hook for renderers that do not yet support rebuilds.
    func invalidate() {}

    /// Default dynamic text implementation for renderers without invalidation.
    func dynamicText(_ value: @escaping () -> String, style: TextStyle, foregroundStyle: ForegroundStyle) {
        text(value(), style: style, foregroundStyle: foregroundStyle)
    }

    /// Default font scope for renderers that do not track inherited text style.
    func beginFont(_ style: TextStyle) {}

    /// Ends a default font scope.
    func endFont() {}

    /// Default hover scope for renderers that do not track pointer movement.
    func beginHover(_ onHover: @escaping (Bool) -> Void) {}

    /// Ends a default hover scope.
    func endHover() {}

    /// Resolves text style with `.body` as the baseline.
    func resolveTextStyle(_ style: TextStyle?) -> TextStyle {
        style ?? .body
    }

    /// Default foreground style scope for renderers that do not track inherited colors.
    func beginForegroundStyle(_ style: ForegroundStyle) {}

    /// Ends a default foreground style scope.
    func endForegroundStyle() {}

    /// Resolves foreground style with `.primary` as the baseline.
    func resolveForegroundStyle() -> ForegroundStyle {
        .primary
    }

    /// Default background scope for renderers that do not paint backgrounds.
    func beginBackground(_ style: Color) {}

    /// Ends a default background scope.
    func endBackground() {}

    /// Default border scope for renderers that do not paint borders.
    func beginBorder(_ color: Color, width: Double) {}

    /// Ends a default border scope.
    func endBorder() {}

    /// Default corner-radius scope for renderers that do not support clipping.
    func beginCornerRadius(_ radius: Double) {}

    /// Ends a default corner-radius scope.
    func endCornerRadius() {}

    /// Resolves no inherited corner radius.
    func resolveCornerRadius() -> Double {
        0
    }

    /// Default divider for renderers that do not support separator lines.
    func divider() {}

    /// Default progress view for renderers without progress support.
    func progressView(_ title: String?, value: @escaping () -> Double, total: Double) {}

    /// Default link for renderers without external URL support.
    func link(_ title: String, destination: String) {}

    /// Default text editor for renderers without multi-line editing support.
    func textEditor(_ prompt: String, text: String, textProvider: (() -> String)?, onChange: ((String) -> Void)?) {}

    /// Default secure field for renderers without password editing support.
    func secureField(_ prompt: String, text: String, textProvider: (() -> String)?, onChange: ((String) -> Void)?) {}

    /// Default stepper for renderers without stepper support.
    func stepper(
        _ title: String,
        value: Int,
        range: ClosedRange<Int>,
        step: Int,
        variant: StepperVariant,
        valueProvider: (() -> Int)?,
        onChange: ((Int) -> Void)?
    ) {}

    /// Default color picker for renderers without color editing support.
    func colorPicker(_ title: String, color: Color, colorProvider: (() -> Color)?, onChange: ((Color) -> Void)?) {}

    /// Default date picker for renderers without date editing support.
    func datePicker(_ title: String, date: CalendarDate, dateProvider: (() -> CalendarDate)?, onChange: ((CalendarDate) -> Void)?) {}
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
