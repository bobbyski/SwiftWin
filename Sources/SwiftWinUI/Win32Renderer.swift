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
    private var fontStack: [TextStyle] = []
    private var foregroundStyleStack: [ForegroundStyle] = []
    private var cornerRadiusStack: [Double] = []
    private var stackAxisStack: [StackAxis] = []

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
        fontStack.removeAll()
        foregroundStyleStack.removeAll()
        cornerRadiusStack.removeAll()
        stackAxisStack.removeAll()
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
        stackAxisStack.append(axis)
        containerPath.append(WinStack(axis: axis.winAxis, spacing: spacing))
    }

    /// Closes the current `WinStack` and appends it to its parent/window.
    public func endStack() {
        if !stackAxisStack.isEmpty {
            stackAxisStack.removeLast()
        }
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

    /// Begins collecting children into a scroll-view container.
    public func beginScrollView() {
        containerPath.append(WinScrollView())
    }

    /// Closes the current scroll-view container.
    public func endScrollView() {
        guard let scrollView = containerPath.popLast() else {
            return
        }

        add(scrollView)
    }

    /// Begins collecting children into a hover callback container.
    public func beginHover(_ onHover: @escaping (Bool) -> Void) {
        containerPath.append(WinHover(onHover: onHover))
    }

    /// Closes the current hover callback container.
    public func endHover() {
        guard let hover = containerPath.popLast() else {
            return
        }

        add(hover)
    }

    /// Begins collecting children into an accessibility metadata container.
    public func beginAccessibility(_ metadata: AccessibilityMetadata) {
        containerPath.append(WinAccessibility(metadata.winAccessibilityMetadata))
    }

    /// Closes the current accessibility metadata container.
    public func endAccessibility() {
        guard let accessibility = containerPath.popLast() else {
            return
        }

        add(accessibility)
    }

    /// Begins an inherited text style scope.
    public func beginFont(_ style: TextStyle) {
        fontStack.append(style)
    }

    /// Ends the current inherited text style scope.
    public func endFont() {
        if !fontStack.isEmpty {
            fontStack.removeLast()
        }
    }

    /// Resolves explicit text style or the nearest inherited font style.
    public func resolveTextStyle(_ style: TextStyle?) -> TextStyle {
        style ?? fontStack.last ?? .body
    }

    /// Begins an inherited foreground style scope.
    public func beginForegroundStyle(_ style: ForegroundStyle) {
        foregroundStyleStack.append(style)
    }

    /// Ends the current inherited foreground style scope.
    public func endForegroundStyle() {
        if !foregroundStyleStack.isEmpty {
            foregroundStyleStack.removeLast()
        }
    }

    /// Resolves the nearest inherited foreground style.
    public func resolveForegroundStyle() -> ForegroundStyle {
        foregroundStyleStack.last ?? .primary
    }

    /// Begins a background container.
    public func beginBackground(_ style: Color) {
        containerPath.append(WinBackground(color: style.winForegroundStyle, cornerRadius: resolveCornerRadius()))
    }

    /// Closes the current background container and appends it to its parent/window.
    public func endBackground() {
        guard let background = containerPath.popLast() else {
            return
        }

        add(background)
    }

    /// Begins a border container.
    public func beginBorder(_ color: Color, width: Double) {
        containerPath.append(WinBorder(color: color.winForegroundStyle, width: width, cornerRadius: resolveCornerRadius()))
    }

    /// Closes the current border container and appends it to its parent/window.
    public func endBorder() {
        guard let border = containerPath.popLast() else {
            return
        }

        add(border)
    }

    /// Begins a corner-radius scope for compatible decoration containers.
    public func beginCornerRadius(_ radius: Double) {
        cornerRadiusStack.append(radius)
    }

    /// Ends the current corner-radius scope.
    public func endCornerRadius() {
        if !cornerRadiusStack.isEmpty {
            cornerRadiusStack.removeLast()
        }
    }

    /// Resolves the nearest inherited corner radius.
    public func resolveCornerRadius() -> Double {
        cornerRadiusStack.last ?? 0
    }

    /// Adapts SwiftWinUI text to `WinText`.
    public func text(_ value: String, style: TextStyle, foregroundStyle: ForegroundStyle) {
        add(WinText(value, style: style.winTextStyle, foregroundStyle: foregroundStyle.winForegroundStyle))
    }

    /// Adapts dynamic SwiftWinUI text to `WinDynamicText`.
    public func dynamicText(_ value: @escaping () -> String, style: TextStyle, foregroundStyle: ForegroundStyle) {
        add(WinDynamicText(value, style: style.winTextStyle, foregroundStyle: foregroundStyle.winForegroundStyle))
    }

    /// Adapts SwiftWinUI button to `WinButton`.
    public func button(_ title: String, style: ButtonStyle, role: ButtonRole?, action: @escaping () -> Void) {
        add(WinButton(title, style: style.winButtonStyle, role: role?.winButtonRole, action: action))
    }

    /// Adapts SwiftWinUI links to `WinLink`.
    public func link(_ title: String, destination: String) {
        add(WinLink(title, destination: destination))
    }

    /// Adapts SwiftWinUI text fields to `WinTextField`.
    public func textField(_ prompt: String, text: String, textProvider: (() -> String)?, onChange: ((String) -> Void)?) {
        add(WinTextField(prompt, text: text, onChange: onChange, textProvider: textProvider))
    }

    /// Adapts SwiftWinUI secure fields to `WinSecureField`.
    public func secureField(_ prompt: String, text: String, textProvider: (() -> String)?, onChange: ((String) -> Void)?) {
        add(WinSecureField(prompt, text: text, onChange: onChange, textProvider: textProvider))
    }

    /// Adapts SwiftWinUI text editors to `WinTextEditor`.
    public func textEditor(_ prompt: String, text: String, textProvider: (() -> String)?, onChange: ((String) -> Void)?) {
        add(WinTextEditor(prompt, text: text, onChange: onChange, textProvider: textProvider))
    }

    /// Adapts SwiftWinUI toggles to `WinToggle`.
    public func toggle(_ title: String, isOn: Bool, valueProvider: (() -> Bool)?, onChange: ((Bool) -> Void)?) {
        add(WinToggle(title, isOn: isOn, onChange: onChange, valueProvider: valueProvider))
    }

    /// Adapts SwiftWinUI pickers to `WinPicker`.
    public func picker(_ title: String, options: [String], selectedIndex: Int, selectionProvider: (() -> Int)?, onChange: ((Int) -> Void)?) {
        add(WinPicker(title, options: options, selectedIndex: selectedIndex, onChange: onChange, selectionProvider: selectionProvider))
    }

    /// Adapts SwiftWinUI sliders to `WinSlider`.
    public func slider(_ title: String, value: Int, range: ClosedRange<Int>, valueProvider: (() -> Int)?, onChange: ((Int) -> Void)?) {
        add(WinSlider(title, value: value, range: range, onChange: onChange, valueProvider: valueProvider))
    }

    /// Adapts SwiftWinUI progress to `WinProgressView`.
    public func progressView(_ title: String?, value: @escaping () -> Double, total: Double) {
        add(WinProgressView(title, value: value, total: total))
    }

    /// Adapts SwiftWinUI steppers to `WinStepper`.
    public func stepper(
        _ title: String,
        value: Int,
        range: ClosedRange<Int>,
        step: Int,
        variant: StepperVariant,
        valueProvider: (() -> Int)?,
        onChange: ((Int) -> Void)?
    ) {
        add(WinStepper(title, value: value, range: range, step: step, variant: variant.winVariant, onChange: onChange, valueProvider: valueProvider))
    }

    /// Adapts SwiftWinUI color pickers to `WinColorPicker`.
    public func colorPicker(_ title: String, color: Color, colorProvider: (() -> Color)?, onChange: ((Color) -> Void)?) {
        add(
            WinColorPicker(
                title,
                color: color.winForegroundStyle,
                onChange: { value in
                    onChange?(value.color)
                },
                colorProvider: {
                    colorProvider?().winForegroundStyle ?? color.winForegroundStyle
                }
            )
        )
    }

    /// Adapts SwiftWinUI date pickers to `WinDatePicker`.
    public func datePicker(
        _ title: String,
        date: CalendarDate,
        dateProvider: (() -> CalendarDate)?,
        onChange: ((CalendarDate) -> Void)?
    ) {
        add(
            WinDatePicker(
                title,
                date: date.winDate,
                onChange: { value in
                    onChange?(value.calendarDate)
                },
                dateProvider: {
                    dateProvider?().winDate ?? date.winDate
                }
            )
        )
    }

    /// Adapts SwiftWinUI spacer to `WinSpacer`.
    public func spacer() {
        add(WinSpacer())
    }

    /// Adapts SwiftWinUI divider to `WinSeparator`.
    public func divider() {
        add(WinSeparator(axis: currentSeparatorAxis(), color: .secondary, thickness: 1))
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

/// Resolves divider orientation from the surrounding stack.
private extension Win32Renderer {
    func currentSeparatorAxis() -> WinSeparatorAxis {
        stackAxisStack.last == .horizontal ? .vertical : .horizontal
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

/// Maps declarative foreground styles to legacy foreground styles.
private extension ForegroundStyle {
    var winForegroundStyle: WinForegroundStyle {
        WinForegroundStyle(red: red, green: green, blue: blue)
    }
}

private extension WinForegroundStyle {
    var color: Color {
        Color(red: red, green: green, blue: blue)
    }
}

private extension CalendarDate {
    var winDate: WinDate {
        WinDate(year: year, month: month, day: day)
    }
}

private extension WinDate {
    var calendarDate: CalendarDate {
        CalendarDate(year: year, month: month, day: day)
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

/// Maps declarative semantic button roles to legacy roles.
private extension ButtonRole {
    var winButtonRole: WinButtonRole {
        switch self {
        case .cancel:
            return .cancel
        case .destructive:
            return .destructive
        }
    }
}

/// Maps declarative accessibility metadata to legacy metadata.
private extension AccessibilityMetadata {
    var winAccessibilityMetadata: WinAccessibilityMetadata {
        WinAccessibilityMetadata(
            label: label,
            role: role?.winAccessibilityRole,
            value: value,
            hint: hint
        )
    }
}

/// Maps declarative accessibility roles to legacy roles.
private extension AccessibilityRole {
    var winAccessibilityRole: WinAccessibilityRole {
        switch self {
        case .text:
            return .text
        case .button:
            return .button
        case .textField:
            return .textField
        case .toggle:
            return .toggle
        case .picker:
            return .picker
        case .slider:
            return .slider
        case .stepper:
            return .stepper
        case .progress:
            return .progress
        case .link:
            return .link
        case .colorPicker:
            return .colorPicker
        case .datePicker:
            return .datePicker
        }
    }
}

private extension StepperVariant {
    /// Maps declarative stepper presentation to the traditional backend.
    var winVariant: WinStepperVariant {
        switch self {
        case .compact:
            return .compact
        case .integratedValue:
            return .integratedValue
        }
    }
}
#endif
