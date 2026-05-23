/// Diagnostic renderer that prints the render stream.
///
/// `ConsoleRenderer` is useful for examples, tests, and non-Windows shells. It
/// intentionally does not invoke actions; it only records the declarative tree
/// shape emitted by views.
public final class ConsoleRenderer: Renderer {
    private var indent = 0
    private var fontStack: [TextStyle] = []
    private var foregroundStyleStack: [ForegroundStyle] = []
    private var cornerRadiusStack: [Double] = []
    private var stackAxisStack: [StackAxis] = []

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
        stackAxisStack.append(axis)
        indent += 1
    }

    /// Ends the current stack node.
    public func endStack() {
        if !stackAxisStack.isEmpty {
            stackAxisStack.removeLast()
        }
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

    /// Prints a foreground-style node.
    public func beginForegroundStyle(_ style: ForegroundStyle) {
        write("ForegroundStyle(red: \(style.red), green: \(style.green), blue: \(style.blue))")
        foregroundStyleStack.append(style)
        indent += 1
    }

    /// Ends the current foreground-style node.
    public func endForegroundStyle() {
        if !foregroundStyleStack.isEmpty {
            foregroundStyleStack.removeLast()
        }
        indent -= 1
    }

    /// Resolves the current foreground style.
    public func resolveForegroundStyle() -> ForegroundStyle {
        foregroundStyleStack.last ?? .primary
    }

    /// Prints a background node.
    public func beginBackground(_ style: Color) {
        write("Background(\(foregroundDescription(style)))")
        indent += 1
    }

    /// Ends the current background node.
    public func endBackground() {
        indent -= 1
    }

    /// Prints a border node.
    public func beginBorder(_ color: Color, width: Double) {
        write("Border(color: \(foregroundDescription(color)), width: \(width))")
        indent += 1
    }

    /// Ends the current border node.
    public func endBorder() {
        indent -= 1
    }

    /// Prints a corner-radius node.
    public func beginCornerRadius(_ radius: Double) {
        write("CornerRadius(\(radius))")
        cornerRadiusStack.append(radius)
        indent += 1
    }

    /// Ends the current corner-radius node.
    public func endCornerRadius() {
        if !cornerRadiusStack.isEmpty {
            cornerRadiusStack.removeLast()
        }
        indent -= 1
    }

    /// Resolves the current corner radius.
    public func resolveCornerRadius() -> Double {
        cornerRadiusStack.last ?? 0
    }

    /// Prints a text node.
    public func text(_ value: String, style: TextStyle, foregroundStyle: ForegroundStyle) {
        write("Text(\"\(value)\", size: \(style.size), weight: \(style.weight), foreground: \(foregroundDescription(foregroundStyle)))")
    }

    /// Prints dynamic text by evaluating its current value.
    public func dynamicText(_ value: @escaping () -> String, style: TextStyle, foregroundStyle: ForegroundStyle) {
        text(value(), style: style, foregroundStyle: foregroundStyle)
    }

    /// Prints a button node.
    public func button(_ title: String, style: ButtonStyle, action: @escaping () -> Void) {
        write("Button(\"\(title)\", style: \(style))")
    }

    /// Prints a text-field node.
    public func textField(_ prompt: String, text: String, textProvider: (() -> String)?, onChange: ((String) -> Void)?) {
        write("TextField(prompt: \"\(prompt)\", text: \"\(text)\")")
    }

    /// Prints a toggle node.
    public func toggle(_ title: String, isOn: Bool, valueProvider: (() -> Bool)?, onChange: ((Bool) -> Void)?) {
        write("Toggle(\"\(title)\", isOn: \(isOn))")
    }

    /// Prints a picker node.
    public func picker(_ title: String, options: [String], selectedIndex: Int, selectionProvider: (() -> Int)?, onChange: ((Int) -> Void)?) {
        write("Picker(\"\(title)\", selectedIndex: \(selectedIndex), options: \(options))")
    }

    /// Prints a slider node.
    public func slider(_ title: String, value: Int, range: ClosedRange<Int>, valueProvider: (() -> Int)?, onChange: ((Int) -> Void)?) {
        write("Slider(\"\(title)\", value: \(value), range: \(range.lowerBound)...\(range.upperBound))")
    }

    /// Prints a stepper node.
    public func stepper(
        _ title: String,
        value: Int,
        range: ClosedRange<Int>,
        step: Int,
        variant: StepperVariant,
        valueProvider: (() -> Int)?,
        onChange: ((Int) -> Void)?
    ) {
        write("Stepper(\"\(title)\", value: \(value), range: \(range.lowerBound)...\(range.upperBound), step: \(step), variant: \(variant))")
    }

    /// Prints a progress-view node.
    public func progressView(_ title: String?, value: @escaping () -> Double, total: Double) {
        write("ProgressView(title: \(optionalDescription(title)), value: \(value()), total: \(total))")
    }

    /// Prints a spacer node.
    public func spacer() {
        write("Spacer()")
    }

    /// Prints a divider node.
    public func divider() {
        let orientation = stackAxisStack.last == .horizontal ? "vertical" : "horizontal"
        write("Divider(axis: \(orientation))")
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

    /// Formats optional strings deterministically.
    private func optionalDescription(_ value: String?) -> String {
        guard let value else {
            return "nil"
        }

        return "\"\(value)\""
    }

    /// Formats foreground colors deterministically for snapshots.
    private func foregroundDescription(_ style: ForegroundStyle) -> String {
        "rgb(\(style.red),\(style.green),\(style.blue))"
    }
}
