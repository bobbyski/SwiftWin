#if os(Windows)
import SwiftWinLegacy

/// Windows renderer for the SwiftUI-compatible layer.
///
/// This renderer intentionally acts as an adapter, not as a second native UI
/// implementation. Declarative SwiftWinUI render calls are converted into
/// `SwiftWinLegacy` imperative objects, and then `WinApplication` owns the
/// native window/runtime path.
public final class Win32Renderer: Renderer {
    private var window: WinWindow?

    // Implementation note:
    // `stackPath` is a construction stack, not a layout stack. It tracks the
    // current parent `WinStack` while the declarative tree is rendered into
    // imperative legacy objects.
    private var containerPath: [WinContainer] = []

    /// Creates a Windows renderer.
    public init() {}

    /// Records that a declarative state mutation occurred.
    ///
    /// Implementation note:
    /// The Win32 backend cannot safely rebuild the native tree yet because
    /// controls are currently emitted directly into child HWNDs. This hook is
    /// intentionally present now so the next renderer iteration has a single
    /// place to schedule diffing/reconciliation.
    public func invalidate() {
        WinDynamicTextInvalidation.invalidateAll()
    }

    /// Starts an imperative `WinWindow` for the current declarative scene.
    public func beginWindow(_ descriptor: WindowDescriptor) {
        window = WinWindow(title: descriptor.title, width: descriptor.width, height: descriptor.height)
        containerPath.removeAll()
    }

    /// Runs the generated `SwiftWinLegacy` window.
    public func endWindow() {
        guard let window else {
            return
        }

        WinApplication().run(window)
    }

    /// Begins collecting children into a `WinStack`.
    public func beginStack(axis: StackAxis, spacing: Double) {
        containerPath.append(WinStack(axis: axis.winAxis, spacing: spacing))
    }

    /// Closes the current `WinStack` and appends it to its parent/window.
    public func endStack() {
        guard let stack = containerPath.popLast() else {
            return
        }

        add(stack)
    }

    /// Begins collecting children into a `WinPadding` container.
    public func beginPadding(_ amount: Double) {
        containerPath.append(WinPadding(amount: amount))
    }

    /// Closes the current `WinPadding` and appends it to its parent/window.
    public func endPadding() {
        guard let padding = containerPath.popLast() else {
            return
        }

        add(padding)
    }

    /// Begins collecting children into a `WinFrame` container.
    public func beginFrame(width: Double?, height: Double?) {
        containerPath.append(WinFrame(width: width, height: height))
    }

    /// Closes the current `WinFrame` and appends it to its parent/window.
    public func endFrame() {
        guard let frame = containerPath.popLast() else {
            return
        }

        add(frame)
    }

    /// Begins collecting children into a `WinDisabled` container.
    public func beginDisabled(_ isDisabled: Bool) {
        containerPath.append(WinDisabled(isDisabled: isDisabled))
    }

    /// Closes the current `WinDisabled` scope and appends it to its parent/window.
    public func endDisabled() {
        guard let disabled = containerPath.popLast() else {
            return
        }

        add(disabled)
    }

    /// Adapts SwiftWinUI text to `WinText`.
    public func text(_ value: String, style: TextStyle) {
        add(WinText(value, style: style.winTextStyle))
    }

    /// Adapts dynamic SwiftWinUI text to `WinDynamicText`.
    public func dynamicText(_ value: @escaping () -> String, style: TextStyle) {
        add(WinDynamicText(value, style: style.winTextStyle))
    }

    /// Adapts SwiftWinUI button to `WinButton`.
    public func button(_ title: String, style: ButtonStyle, action: @escaping () -> Void) {
        add(WinButton(title, style: style.winButtonStyle, action: action))
    }

    /// Adapts SwiftWinUI text fields to `WinTextField`.
    public func textField(_ prompt: String, text: String, onChange: ((String) -> Void)?) {
        add(WinTextField(prompt, text: text, onChange: onChange))
    }

    /// Adapts SwiftWinUI toggles to `WinToggle`.
    public func toggle(_ title: String, isOn: Bool, onChange: ((Bool) -> Void)?) {
        add(WinToggle(title, isOn: isOn, onChange: onChange))
    }

    /// Adapts SwiftWinUI pickers to `WinPicker`.
    public func picker(_ title: String, options: [String], selectedIndex: Int, onChange: ((Int) -> Void)?) {
        add(WinPicker(title, options: options, selectedIndex: selectedIndex, onChange: onChange))
    }

    /// Adapts SwiftWinUI sliders to `WinSlider`.
    public func slider(_ title: String, value: Int, range: ClosedRange<Int>, onChange: ((Int) -> Void)?) {
        add(WinSlider(title, value: value, range: range, onChange: onChange))
    }

    /// Adapts SwiftWinUI spacer to `WinSpacer`.
    public func spacer() {
        add(WinSpacer())
    }

    // Implementation note:
    // Top-level content becomes `window.content`; nested content is appended to
    // the current legacy container. This keeps SwiftWinUI's renderer stateless
    // from the native runtime's perspective.
    private func add(_ element: WinElement) {
        if let parent = containerPath.last {
            parent.add(element)
        } else {
            window?.content = element
        }
    }
}

/// Maps declarative stack axes to legacy stack axes.
private extension StackAxis {
    var winAxis: WinAxis {
        switch self {
        case .horizontal:
            return .horizontal
        case .vertical:
            return .vertical
        }
    }
}

/// Maps declarative text styles to legacy text styles.
private extension TextStyle {
    var winTextStyle: WinTextStyle {
        WinTextStyle(size: size, weight: weight.winFontWeight)
    }
}

/// Maps declarative font weights to legacy font weights.
private extension FontWeight {
    var winFontWeight: WinFontWeight {
        switch self {
        case .regular:
            return .regular
        case .semibold:
            return .semibold
        case .bold:
            return .bold
        }
    }
}

/// Maps declarative button styles to legacy button styles.
private extension ButtonStyle {
    var winButtonStyle: WinButtonStyle {
        switch self {
        case .primary:
            return .primary
        case .secondary:
            return .secondary
        }
    }
}
#endif
