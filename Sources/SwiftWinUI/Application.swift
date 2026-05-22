public protocol App {
    associatedtype Body: Scene

    @SceneBuilder
    var body: Body { get }

    init()
}

public extension App {
    static func main(renderer: Renderer = ConsoleRenderer()) {
        let app = Self()
        let runtime = ApplicationRuntime(renderer: renderer)
        runtime.run(app.body)
    }
}

public protocol Scene {
    func render(into context: RenderContext)
}

@resultBuilder
public enum SceneBuilder {
    public static func buildBlock<S: Scene>(_ scene: S) -> S {
        scene
    }
}

public struct WindowGroup<Content: View>: Scene {
    private let descriptor: WindowDescriptor
    private let content: Content

    public init(
        _ title: String,
        width: Int = 960,
        height: Int = 640,
        @ViewBuilder content: () -> Content
    ) {
        self.descriptor = WindowDescriptor(title: title, width: width, height: height)
        self.content = content()
    }

    public func render(into context: RenderContext) {
        context.renderer.beginWindow(descriptor)
        content.render(into: context)
        context.renderer.endWindow()
    }
}

public struct WindowDescriptor: Sendable, Equatable {
    public var title: String
    public var width: Int
    public var height: Int

    public init(title: String, width: Int, height: Int) {
        self.title = title
        self.width = width
        self.height = height
    }
}

public final class ApplicationRuntime {
    private let renderer: Renderer

    public init(renderer: Renderer) {
        self.renderer = renderer
    }

    public func run<S: Scene>(_ scene: S) {
        scene.render(into: RenderContext(renderer: renderer))
    }
}
