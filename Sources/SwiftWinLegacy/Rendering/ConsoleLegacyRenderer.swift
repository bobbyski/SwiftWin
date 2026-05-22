/// Diagnostic renderer for the traditional element tree.
///
/// This keeps `SwiftWinLegacy` usable from non-Windows environments and gives
/// us a future hook for snapshot tests.
final class ConsoleLegacyRenderer {
    private var indent = 0

    func render(_ window: WinWindow) {
        write("WinWindow(title: \(window.title), size: \(window.width)x\(window.height))")
        indent += 1
        if let content = window.content {
            render(content)
        }
        indent -= 1
    }

    /// Recursively prints a legacy element.
    private func render(_ element: WinElement) {
        switch element {
        case let stack as WinStack:
            write("WinStack(axis: \(stack.axis), spacing: \(stack.spacing))")
            indent += 1
            stack.children.forEach(render)
            indent -= 1
        case let text as WinText:
            write("WinText(\"\(text.value)\", size: \(text.style.size), weight: \(text.style.weight))")
        case let button as WinButton:
            write("WinButton(\"\(button.title)\", style: \(button.style))")
        case let textField as WinTextField:
            write("WinTextField(prompt: \"\(textField.prompt)\", value: \"\(textField.value)\")")
        case is WinSpacer:
            write("WinSpacer()")
        default:
            write("UnknownElement()")
        }
    }

    /// Writes an indented diagnostic line.
    private func write(_ value: String) {
        print(String(repeating: "  ", count: indent) + value)
    }
}
