/// Diagnostic renderer that prints the render stream.
///
/// `ConsoleRenderer` is useful for examples, tests, and non-Windows shells. It
/// intentionally does not invoke actions; it only records the declarative tree
/// shape emitted by views.
public final class ConsoleRenderer: Renderer {
    private var indent = 0
    private var fontStack: [TextStyle] = []

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

    /// Prints a padding node.
    public func beginPadding(_ amount: Double) {
        write("Padding(\(amount))")
        indent += 1
    }

    /// Ends the current padding node.
    public func endPadding() {
        indent -= 1
    }

    /// Prints a frame node.
    public func beginFrame(width: Double?, height: Double?) {
        write("Frame(width: \(optionalDescription(width)), height: \(optionalDescription(height)))")
        indent += 1
    }

    /// Ends the current frame node.
    public func endFrame() {
        indent -= 1
    }

    /// Prints a disabled-state node.
    public func beginDisabled(_ isDisabled: Bool) {
        write("Disabled(\(isDisabled))")
        indent += 1
    }

    /// Ends the current disabled-state node.
    public func endDisabled() {
        indent -= 1
    }

    /// Prints a font node.
    public func beginFont(_ style: TextStyle) {
        write("Font(size: \(style.size), weight: \(style.weight))")
        fontStack.append(style)
        indent += 1
    }

    /// Ends the current font node.
    public func endFont() {
        if !fontStack.isEmpty {
            fontStack.removeLast()
        }
        indent -= 1
    }

    /// Resolves explicit text style or current font scope.
    public func resolveTextStyle(_ style: TextStyle?) -> TextStyle {
        style ?? fontStack.last ?? .body
    }

    /// Prints a text node.
    public func text(_ value: String, style: TextStyle) {
        write("Text(\"\(value)\", size: \(style.size), weight: \(style.weight))")
    }

    /// Prints dynamic text by evaluating its current value.
    public func dynamicText(_ value: @escaping () -> String, style: TextStyle) {
        text(value(), style: style)
    }

    /// Prints a button node.
    public func button(_ title: String, style: ButtonStyle, action: @escaping () -> Void) {
        write("Button(\"\(title)\", style: \(style))")
    }

    /// Prints a text-field node.
    public func textField(_ prompt: String, text: String, onChange: ((String) -> Void)?) {
        write("TextField(prompt: \"\(prompt)\", text: \"\(text)\")")
    }

    /// Prints a toggle node.
    public func toggle(_ title: String, isOn: Bool, onChange: ((Bool) -> Void)?) {
        write("Toggle(\"\(title)\", isOn: \(isOn))")
    }

    /// Prints a picker node.
    public func picker(_ title: String, options: [String], selectedIndex: Int, onChange: ((Int) -> Void)?) {
        write("Picker(\"\(title)\", selectedIndex: \(selectedIndex), options: \(options))")
    }

    /// Prints a slider node.
    public func slider(_ title: String, value: Int, range: ClosedRange<Int>, onChange: ((Int) -> Void)?) {
        write("Slider(\"\(title)\", value: \(value), range: \(range.lowerBound)...\(range.upperBound))")
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

    /// Formats optional numeric values deterministically.
    private func optionalDescription(_ value: Double?) -> String {
        guard let value else {
            return "nil"
        }

        return "\(value)"
    }
}
