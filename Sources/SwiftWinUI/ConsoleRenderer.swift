/// Diagnostic renderer that prints the render stream.
///
/// `ConsoleRenderer` is useful for examples, tests, and non-Windows shells. It
/// intentionally does not invoke actions; it only records the declarative tree
/// shape emitted by views.
public final class ConsoleRenderer: Renderer {
    private var indent = 0

    /// Creates a console renderer.
    public init() {}

    /// Prints a window node.
    public func beginWindow(_ descriptor: WindowDescriptor) {
        write("Window(title: \(descriptor.title), size: \(descriptor.width)x\(descriptor.height))")
        indent += 1
    }

    /// Ends the current window node.
    public func endWindow() {
        indent -= 1
    }

    /// Prints a stack node.
    public func beginStack(axis: StackAxis, spacing: Double) {
        write("\(axis == .vertical ? "VStack" : "HStack")(spacing: \(spacing))")
        indent += 1
    }

    /// Ends the current stack node.
    public func endStack() {
        indent -= 1
    }

    /// Prints a text node.
    public func text(_ value: String, style: TextStyle) {
        write("Text(\"\(value)\", size: \(style.size), weight: \(style.weight))")
    }

    /// Prints a button node.
    public func button(_ title: String, style: ButtonStyle, action: @escaping () -> Void) {
        write("Button(\"\(title)\", style: \(style))")
    }

    /// Prints a text-field node.
    public func textField(_ prompt: String, text: String, onChange: ((String) -> Void)?) {
        write("TextField(prompt: \"\(prompt)\", text: \"\(text)\")")
    }

    /// Prints a spacer node.
    public func spacer() {
        write("Spacer()")
    }

    // Implementation note:
    // Keep formatting deterministic so future snapshot tests can compare
    // console output without unstable whitespace or platform-specific detail.
    private func write(_ message: String) {
        print(String(repeating: "  ", count: indent) + message)
    }
}
