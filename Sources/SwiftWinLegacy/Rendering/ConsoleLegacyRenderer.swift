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
        case let padding as WinPadding:
            write("WinPadding(amount: \(padding.amount))")
            indent += 1
            padding.children.forEach(render)
            indent -= 1
        case let frame as WinFrame:
            write("WinFrame(width: \(optionalDescription(frame.width)), height: \(optionalDescription(frame.height)))")
            indent += 1
            frame.children.forEach(render)
            indent -= 1
        case let disabled as WinDisabled:
            write("WinDisabled(isDisabled: \(disabled.isDisabled))")
            indent += 1
            disabled.children.forEach(render)
            indent -= 1
        case let text as WinText:
            write("WinText(\"\(text.value)\", size: \(text.style.size), weight: \(text.style.weight))")
        case let text as WinDynamicText:
            write("WinDynamicText(\"\(text.value)\", size: \(text.style.size), weight: \(text.style.weight))")
        case let button as WinButton:
            write("WinButton(\"\(button.title)\", style: \(button.style))")
        case let link as WinLink:
            write("WinLink(\"\(link.title)\", destination: \"\(link.destination)\")")
        case let textField as WinTextField:
            write("WinTextField(prompt: \"\(textField.prompt)\", value: \"\(textField.value)\")")
        case let secureField as WinSecureField:
            write("WinSecureField(prompt: \"\(secureField.prompt)\", value: \"<redacted>\")")
        case let textEditor as WinTextEditor:
            write("WinTextEditor(prompt: \"\(textEditor.prompt)\", value: \"\(textEditor.value)\")")
        case let toggle as WinToggle:
            write("WinToggle(\"\(toggle.title)\", isOn: \(toggle.isOn))")
        case let picker as WinPicker:
            write("WinPicker(\"\(picker.title)\", selectedIndex: \(picker.selectedIndex), options: \(picker.options))")
        case let slider as WinSlider:
            write("WinSlider(\"\(slider.title)\", value: \(slider.value), range: \(slider.minimum)...\(slider.maximum))")
        case let stepper as WinStepper:
            write("WinStepper(\"\(stepper.title)\", value: \(stepper.value), range: \(stepper.minimum)...\(stepper.maximum), step: \(stepper.step), variant: \(stepper.variant))")
        case let progressView as WinProgressView:
            write("WinProgressView(title: \(optionalDescription(progressView.title)), value: \(progressView.value), total: \(progressView.total))")
        case let separator as WinSeparator:
            write("WinSeparator(axis: \(separator.axis), thickness: \(separator.thickness))")
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
}
