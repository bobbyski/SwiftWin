/// The SwiftUI-compatible application entry point for SwiftWinUI apps.
///
/// `App` intentionally mirrors SwiftUI's top-level app shape:
///
/// ```swift
/// struct DemoApp: App {
///     var body: some Scene {
///         WindowGroup("Demo") {
///             Text("Hello")
///         }
///     }
/// }
/// ```
///
/// The current runtime supports a single rendered scene. Future versions should
/// extend this toward SwiftUI-compatible scene lifecycles and multiple windows.
public protocol App {
    /// The concrete scene type produced by this app.
    associatedtype Body: Scene

    /// The root scene graph for the application.
    @SceneBuilder
    var body: Body { get }

    /// Creates an app instance for `main()`.
    init()
}

public extension App {
    /// Starts the app with the platform default renderer.
    ///
    /// On Windows this uses `Win32Renderer`, which adapts the declarative
    /// SwiftWinUI tree into `SwiftWinLegacy` controls. On non-Windows platforms
    /// it uses `ConsoleRenderer` so examples can still be inspected.
    static func main() {
        main(renderer: defaultRenderer())
    }

    /// Starts the app with an explicit renderer.
    ///
    /// This overload is useful for diagnostics and tests, especially with
    /// `ConsoleRenderer`.
    static func main(renderer: Renderer) {
        let app = Self()
        let runtime = ApplicationRuntime(renderer: renderer)
        runtime.run(app.body)
    }
}

// Implementation note:
// Keep the default renderer selection in one place so the public `App` API
// stays SwiftUI-shaped. Platform differences should live behind renderers, not
// leak into user app declarations.
private func defaultRenderer() -> Renderer {
    #if os(Windows)
    Win32Renderer()
    #else
    ConsoleRenderer()
    #endif
}

/// A top-level renderable surface in a SwiftWinUI app.
///
/// This mirrors SwiftUI's `Scene` concept. Today the only scene implementation
/// is `WindowGroup`; future scenes may include settings windows, document
/// groups, menu bar/tray apps, and modal surfaces.
public protocol Scene {
    /// Renders this scene into a renderer context.
    func render(into context: RenderContext)
}

/// Result builder for app scene declarations.
///
/// This is intentionally minimal while the framework only supports a single
/// root scene. More SwiftUI-compatible scene builder forms can be added as the
/// scene model expands.
@resultBuilder
public enum SceneBuilder {
    /// Builds a single scene.
    public static func buildBlock<S: Scene>(_ scene: S) -> S {
        scene
    }
}

/// A top-level window scene.
///
/// `WindowGroup` mirrors SwiftUI naming. The current implementation creates one
/// native window; true SwiftUI-style window grouping is planned later.
public struct WindowGroup<Content: View>: Scene {
    private let descriptor: WindowDescriptor
    private let content: Content

    /// Creates a window scene.
    ///
    /// - Parameters:
    ///   - title: The native window title.
    ///   - width: Initial window width in platform pixels for the current
    ///     prototype.
    ///   - height: Initial window height in platform pixels for the current
    ///     prototype.
    ///   - content: Declarative view content rendered inside the window.
    public init(
        _ title: String,
        width: Int = 960,
        height: Int = 640,
        @ViewBuilder content: () -> Content
    ) {
        self.descriptor = WindowDescriptor(title: title, width: width, height: height)
        self.content = content()
    }

    /// Emits window begin/end calls around the scene content.
    public func render(into context: RenderContext) {
        context.renderer.beginWindow(descriptor)
        content.render(into: context)
        context.renderer.endWindow()
    }
}

/// Platform-neutral description of a window requested by `WindowGroup`.
public struct WindowDescriptor: Sendable, Equatable {
    /// Native window title.
    public var title: String
    /// Initial native window width.
    public var width: Int
    /// Initial native window height.
    public var height: Int

    /// Creates a window descriptor.
    public init(title: String, width: Int, height: Int) {
        self.title = title
        self.width = width
        self.height = height
    }
}

/// Runs a rendered scene through a renderer.
///
/// `ApplicationRuntime` is intentionally thin. Native lifecycle ownership lives
/// in renderer/runtime implementations so `App` can stay close to SwiftUI.
public final class ApplicationRuntime {
    private let renderer: Renderer

    /// Creates a runtime backed by `renderer`.
    public init(renderer: Renderer) {
        self.renderer = renderer
    }

    /// Renders and runs a scene.
    public func run<S: Scene>(_ scene: S) {
        scene.render(into: RenderContext(renderer: renderer))
    }
}
