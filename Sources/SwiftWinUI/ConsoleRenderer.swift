public final class ConsoleRenderer: Renderer {
    private var indent = 0

    public init() {}

    public func beginWindow(_ descriptor: WindowDescriptor) {
        write("Window(title: \(descriptor.title), size: \(descriptor.width)x\(descriptor.height))")
        indent += 1
    }

    public func endWindow() {
        indent -= 1
    }

    public func beginStack(axis: StackAxis, spacing: Double) {
        write("\(axis == .vertical ? "VStack" : "HStack")(spacing: \(spacing))")
        indent += 1
    }

    public func endStack() {
        indent -= 1
    }

    public func text(_ value: String, style: TextStyle) {
        write("Text(\"\(value)\", size: \(style.size), weight: \(style.weight))")
    }

    public func button(_ title: String, action: @escaping () -> Void) {
        write("Button(\"\(title)\")")
    }

    public func spacer() {
        write("Spacer()")
    }

    private func write(_ message: String) {
        print(String(repeating: "  ", count: indent) + message)
    }
}
