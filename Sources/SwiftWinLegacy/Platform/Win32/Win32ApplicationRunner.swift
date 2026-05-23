#if os(Windows)
/// Native Win32 runner for the traditional API.
///
/// Implementation decision:
/// This type owns tree traversal and native control creation for now, while
/// lower-level declarations, message handling, and painting live in sibling
/// platform files. Keep new helpers small and move responsibilities out as they
/// become reusable.
final class Win32ApplicationRunner {
    private var instance: HINSTANCE?
    private var window: HWND?
    private var layoutStack: [LayoutState] = []
    private var backgroundStack: [BackgroundLayoutState] = []
    private var borderStack: [BorderLayoutState] = []
    private var nextControlID: UInt16 = 100
    private var fonts: [WinTextStyle: HFONT] = [:]

    /// Creates native controls from a `WinWindow` and starts the message loop.
    func run(_ descriptor: WinWindow) {
        Win32ActionRegistry.reset()
        instance = GetModuleHandleW(nil)
        configureProcessDPIAwareness()
        initializeCommonControls()
        Win32PaintResources.backgroundBrush = CreateSolidBrush(0x00fbf8f7)
        Win32PaintResources.controlSurfaceBrush = CreateSolidBrush(0x00fff6ef)
        registerWindowClass()
        createWindow(descriptor)
        layoutStack = [
            LayoutState(
                axis: .vertical,
                x: Win32LayoutMetrics.rootInset,
                y: Win32LayoutMetrics.rootTop,
                spacing: Win32LayoutMetrics.stackSpacing
            )
        ]

        if let content = descriptor.content {
            render(content)
            updateContentHeight()
        }

        guard let window else {
            return
        }

        _ = ShowWindow(window, SW_SHOW)
        _ = UpdateWindow(window)
        runMessageLoop()
    }

    /// Creates the top-level HWND for a window descriptor.
    private func createWindow(_ descriptor: WinWindow) {
        withWideString("SwiftWinLegacyWindow") { className in
            withWideString(descriptor.title) { title in
                window = CreateWindowExW(
                    0,
                    className,
                    title,
                    WS_OVERLAPPEDWINDOW,
                    CW_USEDEFAULT,
                    CW_USEDEFAULT,
                    Int32(descriptor.width),
                    Int32(descriptor.height),
                    nil,
                    nil,
                    instance,
                    nil
                )
            }
        }
    }

    /// Traverses the imperative element tree and creates native controls.
    private func render(_ element: WinElement) {
        switch element {
        case let stack as WinStack:
            beginStack(axis: stack.axis, spacing: stack.spacing)
            stack.children.forEach(render)
            endStack()
        case let padding as WinPadding:
            beginPadding(padding.amount)
            padding.children.forEach(render)
            endPadding(padding.amount)
        case let frame as WinFrame:
            beginFrame(width: frame.width, height: frame.height)
            frame.children.forEach(render)
            endFrame(width: frame.width, height: frame.height)
        case let background as WinBackground:
            beginBackground(color: background.color, cornerRadius: background.cornerRadius)
            background.children.forEach(render)
            endBackground()
        case let border as WinBorder:
            beginBorder(color: border.color, width: border.width, cornerRadius: border.cornerRadius)
            border.children.forEach(render)
            endBorder()
        case let disabled as WinDisabled:
            beginDisabled(disabled.isDisabled)
            disabled.children.forEach(render)
            endDisabled()
        case let text as WinText:
            createText(text.value, style: text.style, foregroundStyle: text.foregroundStyle)
        case let text as WinDynamicText:
            createDynamicText(text)
        case let button as WinButton:
            createButton(button.title, style: button.style, action: button.action)
        case let textField as WinTextField:
            createTextField(textField)
        case let toggle as WinToggle:
            createToggle(toggle)
        case let picker as WinPicker:
            createPicker(picker)
        case let slider as WinSlider:
            createSlider(slider)
        case let stepper as WinStepper:
            createStepper(stepper)
        case let progressView as WinProgressView:
            createProgressView(progressView)
        case let separator as WinSeparator:
            createSeparator(separator)
        case is WinSpacer:
            advance(width: 20, height: 20)
        default:
            break
        }
    }

    /// Pushes a stack layout context.
    ///
    /// Implementation note:
    /// This is a direct-placement prototype, not a real layout engine. Each
    /// stack records its starting point and advances coordinates as children
    /// are created.
    private func beginStack(axis: WinAxis, spacing: Double) {
        let origin = layoutStack.last ?? LayoutState(axis: .vertical, x: 36, y: 34, spacing: 12)
        layoutStack.append(LayoutState(axis: axis, x: origin.x, y: origin.y, spacing: Int32(spacing), isDisabled: origin.isDisabled))
    }

    /// Pops a stack context and advances its parent by the consumed size.
    private func endStack() {
        guard layoutStack.count > 1, let child = layoutStack.popLast() else {
            return
        }

        let size = consumedSize(of: child)
        advance(width: size.width, height: size.height)
    }

    /// Pushes an inset layout context.
    private func beginPadding(_ amount: Double) {
        let inset = Int32(amount)
        let origin = layoutStack.last ?? LayoutState(axis: .vertical, x: 36, y: 34, spacing: 12)
        layoutStack.append(
            LayoutState(
                axis: origin.axis,
                x: origin.x + inset,
                y: origin.y + inset,
                spacing: origin.spacing,
                isDisabled: origin.isDisabled
            )
        )
    }

    /// Pops an inset layout context and advances the parent by padded size.
    private func endPadding(_ amount: Double) {
        guard layoutStack.count > 1, let child = layoutStack.popLast() else {
            return
        }

        let inset = Int32(amount)
        let size = consumedSize(of: child)
        advance(width: size.width + inset * 2, height: size.height + inset * 2)
    }

    /// Pushes a fixed-size layout proposal.
    private func beginFrame(width: Double?, height: Double?) {
        let origin = layoutStack.last ?? LayoutState(axis: .vertical, x: 36, y: 34, spacing: 12)
        layoutStack.append(
            LayoutState(
                axis: origin.axis,
                x: origin.x,
                y: origin.y,
                spacing: origin.spacing,
                proposedWidth: int32(width),
                proposedHeight: int32(height),
                isDisabled: origin.isDisabled
            )
        )
    }

    /// Pops a fixed-size proposal and advances the parent by the resolved size.
    private func endFrame(width: Double?, height: Double?) {
        guard layoutStack.count > 1, let child = layoutStack.popLast() else {
            return
        }

        let size = consumedSize(of: child)
        advance(width: int32(width) ?? size.width, height: int32(height) ?? size.height)
    }

    /// Pushes a background panel layout context.
    private func beginBackground(color: WinForegroundStyle, cornerRadius: Double) {
        let origin = layoutStack.last ?? LayoutState(axis: .vertical, x: 36, y: 34, spacing: 12)
        let panel = createBackgroundPanel(color: color, cornerRadius: cornerRadius, x: origin.x, y: origin.y)
        backgroundStack.append(BackgroundLayoutState(control: panel, x: origin.x, y: origin.y))
        layoutStack.append(origin)
    }

    /// Pops a background context, sizes the panel, and advances the parent.
    private func endBackground() {
        guard layoutStack.count > 1,
              let child = layoutStack.popLast(),
              let background = backgroundStack.popLast() else {
            return
        }

        let size = consumedSize(of: child)
        resizeBackgroundPanel(background, width: size.width, height: size.height)
        advance(width: size.width, height: size.height)
    }

    /// Pushes a border layout context.
    private func beginBorder(color: WinForegroundStyle, width: Double, cornerRadius: Double) {
        let origin = layoutStack.last ?? LayoutState(axis: .vertical, x: 36, y: 34, spacing: 12)
        borderStack.append(
            BorderLayoutState(
                x: origin.x,
                y: origin.y,
                color: color,
                width: max(1, Int32(width)),
                cornerRadius: max(0, Int32(cornerRadius))
            )
        )
        layoutStack.append(origin)
    }

    /// Pops a border context, creates its drawing panel, and advances the parent.
    private func endBorder() {
        guard layoutStack.count > 1,
              let child = layoutStack.popLast(),
              let border = borderStack.popLast() else {
            return
        }

        let size = consumedSize(of: child)
        createBorderPanel(border, width: size.width, height: size.height)
        advance(width: size.width, height: size.height)
    }

    /// Pushes a disabled-state scope.
    private func beginDisabled(_ isDisabled: Bool) {
        let origin = layoutStack.last ?? LayoutState(axis: .vertical, x: 36, y: 34, spacing: 12)
        layoutStack.append(
            LayoutState(
                axis: origin.axis,
                x: origin.x,
                y: origin.y,
                spacing: origin.spacing,
                proposedWidth: origin.proposedWidth,
                proposedHeight: origin.proposedHeight,
                isDisabled: origin.isDisabled || isDisabled
            )
        )
    }

    /// Pops a disabled-state scope and advances the parent by consumed size.
    private func endDisabled() {
        guard layoutStack.count > 1, let child = layoutStack.popLast() else {
            return
        }

        let size = consumedSize(of: child)
        advance(width: size.width, height: size.height)
    }

    /// Creates a native static text control.
    ///
    /// SDK polish rule:
    /// Text controls use shared Win32 layout metrics by default. App authors
    /// should not need to know that Win32 `STATIC` controls clip descenders or
    /// need extra width for large semantic styles.
    @discardableResult
    private func createText(
        _ value: String,
        style: WinTextStyle,
        foregroundStyle: WinForegroundStyle = .primary
    ) -> HWND? {
        if let control = createControl(
            className: "STATIC",
            title: value,
            style: WS_CHILD | WS_VISIBLE | SS_LEFT,
            width: proposedWidth(defaultingTo: Win32LayoutMetrics.textWidth(for: value, style: style)),
            height: proposedHeight(defaultingTo: Win32LayoutMetrics.textHeight(for: style)),
            action: nil,
            textForegroundStyle: foregroundStyle
        ) {
            applyFont(style, to: control)
            return control
        }

        return nil
    }

    /// Creates a native static text control backed by a dynamic provider.
    private func createDynamicText(_ text: WinDynamicText) {
        if let control = createText(text.value, style: text.style, foregroundStyle: text.foregroundStyle) {
            let controlID = UInt16(GetDlgCtrlID(control))
            let state = DynamicTextRenderState(text: text, control: control)
            Win32ActionRegistry.dynamicTexts[controlID] = state
        }
    }

    /// Creates an owner-drawn native button.
    ///
    /// Implementation note:
    /// Win32's stock buttons did not provide enough visual differentiation for
    /// our prototype. `BS_OWNERDRAW` keeps native click/focus behavior while
    /// letting us paint primary and secondary appearances ourselves.
    private func createButton(_ title: String, style buttonStyle: WinButtonStyle, action: @escaping () -> Void) {
        if let control = createControl(
            className: "BUTTON",
            title: title,
            style: WS_CHILD | WS_VISIBLE | WS_TABSTOP | BS_OWNERDRAW,
            width: proposedWidth(defaultingTo: max(buttonStyle == .primary ? 136 : 116, Int32(title.count * 9 + 48))),
            height: proposedHeight(defaultingTo: 40),
            action: action,
            button: ButtonRenderState(title: title, style: buttonStyle)
        ) {
            applyFont(.body, to: control)
        }
    }

    /// Creates an owner-drawn separator line.
    private func createSeparator(_ separator: WinSeparator) {
        let thickness = max(1, Int32(separator.thickness))
        let defaultWidth = separator.axis == .horizontal ? 340 : thickness + 8
        let defaultHeight = separator.axis == .horizontal ? thickness + 8 : 32
        let controlID = nextControlID

        if let control = createControl(
            className: "STATIC",
            title: "",
            style: WS_CHILD | WS_VISIBLE | SS_OWNERDRAW,
            width: proposedWidth(defaultingTo: defaultWidth),
            height: proposedHeight(defaultingTo: defaultHeight),
            action: nil
        ) {
            Win32ActionRegistry.separators[UInt32(controlID)] = SeparatorRenderState(
                axis: separator.axis,
                color: separator.color,
                thickness: thickness
            )
            _ = EnableWindow(control, 0)
        }
    }

    /// Creates a native single-line edit control.
    private func createTextField(_ field: WinTextField) {
        if let control = createControl(
            className: "EDIT",
            title: field.value,
            style: WS_CHILD | WS_VISIBLE | WS_TABSTOP | WS_BORDER | ES_AUTOHSCROLL,
            width: proposedWidth(defaultingTo: 280),
            height: proposedHeight(defaultingTo: 32),
            action: nil,
            textField: field
        ) {
            applyFont(.body, to: control)
            setPlaceholder(field.prompt, for: control)
        }
    }

    /// Creates a native checkbox control.
    private func createToggle(_ toggle: WinToggle) {
        if let control = createControl(
            className: "BUTTON",
            title: toggle.title,
            style: WS_CHILD | WS_VISIBLE | WS_TABSTOP | BS_OWNERDRAW,
            width: proposedWidth(defaultingTo: max(180, Int32(toggle.title.count * 9 + 44))),
            height: proposedHeight(defaultingTo: 32),
            action: nil,
            toggle: toggle
        ) {
            applyFont(.body, to: control)
        }
    }

    /// Creates a radio-button segmented picker.
    private func createPicker(_ picker: WinPicker) {
        createText(picker.title, style: .caption)
        beginStack(axis: .horizontal, spacing: 8)
        for index in picker.options.indices {
            createPickerOption(picker, index: index)
        }
        endStack()
    }

    /// Creates one radio button for a picker option.
    private func createPickerOption(_ picker: WinPicker, index: Int) {
        let title = picker.options[index]
        let style = pickerOptionStyle(index: index)
        if let control = createControl(
            className: "BUTTON",
            title: title,
            style: style | BS_OWNERDRAW,
            width: proposedWidth(defaultingTo: max(96, Int32(title.count * 9 + 42))),
            height: proposedHeight(defaultingTo: 32),
            action: nil,
            pickerOption: PickerOptionState(picker: picker, index: index)
        ) {
            applyFont(.body, to: control)
        }
    }

    /// Returns radio-button style flags for a picker option.
    private func pickerOptionStyle(index: Int) -> DWORD {
        var style = WS_CHILD | WS_VISIBLE | WS_TABSTOP | BS_AUTORADIOBUTTON
        if index == 0 {
            style |= WS_GROUP
        }
        return style
    }

    /// Initializes modern common-control classes used by the backend.
    private func initializeCommonControls() {
        var controls = INITCOMMONCONTROLSEX(
            dwSize: DWORD(MemoryLayout<INITCOMMONCONTROLSEX>.size),
            dwICC: ICC_BAR_CLASSES | ICC_PROGRESS_CLASS
        )
        _ = InitCommonControlsEx(&controls)
    }

    /// Requests crisp, modern DPI behavior for the current process.
    ///
    /// Windows oddity for Apple developers:
    /// Win32 processes are not automatically per-monitor DPI aware. Without
    /// opting in, Windows may scale the app as a bitmap on high-DPI displays,
    /// which makes otherwise fine controls look soft or dated.
    private func configureProcessDPIAwareness() {
        let context = dpiAwarenessContextPerMonitorV2()
        if SetProcessDpiAwarenessContext(context) == 0 {
            _ = SetProcessDPIAware()
        }
    }

    /// Returns the Win32 sentinel handle for per-monitor DPI v2 awareness.
    private func dpiAwarenessContextPerMonitorV2() -> HANDLE? {
        HANDLE(bitPattern: -4)
    }

    /// Creates a native horizontal range control.
    private func createSlider(_ slider: WinSlider) {
        let label = createText(sliderDisplayText(slider), style: .caption)
        if let label, let control = createControl(
            className: "msctls_trackbar32",
            title: "",
            style: WS_CHILD | WS_VISIBLE | WS_TABSTOP | TBS_AUTOTICKS,
            width: proposedWidth(defaultingTo: 280),
            height: proposedHeight(defaultingTo: 36),
            action: nil
        ) {
            let state = SliderRenderState(slider: slider, label: label)
            Win32ActionRegistry.slidersByHandle[UInt(bitPattern: control)] = state
            _ = SendMessageW(control, TBM_SETRANGE, 1, makeLong(low: slider.minimum, high: slider.maximum))
            _ = SendMessageW(control, TBM_SETPOS, 1, LPARAM(slider.value))
        }
    }

    /// Creates a composite integer stepper.
    private func createStepper(_ stepper: WinStepper) {
        switch stepper.variant {
        case .compact:
            createCompactStepper(stepper)
        case .integratedValue:
            createIntegratedStepper(stepper)
        }
    }

    /// Creates the compact stepper variant: title/value plus two buttons.
    private func createCompactStepper(_ stepper: WinStepper) {
        guard let label = createText(stepperDisplayText(stepper), style: .caption) else {
            return
        }

        beginStack(axis: .horizontal, spacing: 8)
        createStepperButton("-", stepper: stepper, delta: -stepper.step, label: { label }, displaysValueOnly: false)
        createStepperButton("+", stepper: stepper, delta: stepper.step, label: { label }, displaysValueOnly: false)
        endStack()
    }

    /// Creates the integrated stepper variant: title plus `- | value | +`.
    private func createIntegratedStepper(_ stepper: WinStepper) {
        createText(stepper.title, style: .caption)

        var valueLabel: HWND?
        beginStack(axis: .horizontal, spacing: 0)
        createStepperButton(
            "-",
            stepper: stepper,
            delta: -stepper.step,
            label: { valueLabel },
            displaysValueOnly: true,
            segmentRole: .leading
        )
        valueLabel = createStepperValueLabel(stepper)
        createStepperButton(
            "+",
            stepper: stepper,
            delta: stepper.step,
            label: { valueLabel },
            displaysValueOnly: true,
            segmentRole: .trailing
        )
        endStack()
    }

    /// Creates the value label used inside the integrated stepper row.
    private func createStepperValueLabel(_ stepper: WinStepper) -> HWND? {
        let control = createControl(
            className: "STATIC",
            title: stepperValueText(stepper),
            style: WS_CHILD | WS_VISIBLE | SS_OWNERDRAW,
            width: 64,
            height: 34,
            action: nil,
            textForegroundStyle: .primary
        )
        if let control {
            let controlID = UInt32(GetDlgCtrlID(control))
            Win32ActionRegistry.stepperValues[controlID] = StepperValueRenderState(stepper: stepper)
            applyFont(.body, to: control)
        }
        return control
    }

    /// Creates one owner-drawn button for a stepper action.
    private func createStepperButton(
        _ title: String,
        stepper: WinStepper,
        delta: Int,
        label: @escaping () -> HWND?,
        displaysValueOnly: Bool,
        segmentRole: SegmentedControlRole? = nil
    ) {
        if let control = createControl(
            className: "BUTTON",
            title: title,
            style: WS_CHILD | WS_VISIBLE | WS_TABSTOP | BS_OWNERDRAW,
            width: 44,
            height: 34,
            action: { [weak self, weak stepper] in
                guard let self, let stepper else {
                    return
                }
                guard let label = label() else {
                    return
                }
                self.set(
                    stepper: stepper,
                    value: stepper.value + delta,
                    label: label,
                    displaysValueOnly: displaysValueOnly
                )
            },
            button: ButtonRenderState(title: title, style: .secondary, segmentRole: segmentRole)
        ) {
            applyFont(.body, to: control)
        }
    }

    /// Creates a native determinate progress bar.
    private func createProgressView(_ progressView: WinProgressView) {
        if let title = progressView.title {
            createText(title, style: .caption, foregroundStyle: .secondary)
        }

        if let control = createControl(
            className: "msctls_progress32",
            title: "",
            style: WS_CHILD | WS_VISIBLE,
            width: proposedWidth(defaultingTo: 280),
            height: proposedHeight(defaultingTo: 18),
            action: nil
        ) {
            Win32ActionRegistry.progressViews[UInt(bitPattern: control)] = ProgressRenderState(
                progressView: progressView,
                control: control
            )
            _ = SendMessageW(control, PBM_SETRANGE, 0, makeLong(low: 0, high: 1000))
            _ = SendMessageW(control, PBM_SETPOS, WPARAM(progressPosition(for: progressView)), 0)
        }
    }

    /// Formats the native value label for a slider.
    private func sliderDisplayText(_ slider: WinSlider) -> String {
        "\(slider.title): \(slider.value)"
    }

    /// Formats the native value label for a stepper.
    private func stepperDisplayText(_ stepper: WinStepper) -> String {
        "\(stepper.title): \(stepper.value)"
    }

    /// Formats the value-only label for an integrated stepper.
    private func stepperValueText(_ stepper: WinStepper) -> String {
        "\(stepper.value)"
    }

    /// Stores a stepper value and mirrors it back to the native label.
    private func set(stepper: WinStepper, value: Int, label: HWND, displaysValueOnly: Bool) {
        let clamped = min(max(value, stepper.minimum), stepper.maximum)
        guard clamped != stepper.value else {
            return
        }

        stepper.value = clamped
        updateStepperLabel(label, stepper: stepper, displaysValueOnly: displaysValueOnly)
        stepper.onChange?(clamped)
        WinDynamicTextInvalidation.invalidateAll()
    }

    /// Updates the static text label owned by a stepper.
    private func updateStepperLabel(_ label: HWND, stepper: WinStepper, displaysValueOnly: Bool) {
        let value = displaysValueOnly ? stepperValueText(stepper) : stepperDisplayText(stepper)
        withWideString(value) { text in
            _ = SetWindowTextW(label, text)
        }
    }

    /// Registers the window class used by SwiftWinLegacy windows.
    private func registerWindowClass() {
        withWideString("SwiftWinLegacyWindow") { className in
            var windowClass = WNDCLASSEXW(
                cbSize: UInt32(MemoryLayout<WNDCLASSEXW>.size),
                style: CS_HREDRAW | CS_VREDRAW,
                lpfnWndProc: swiftWinLegacyWindowProc,
                cbClsExtra: 0,
                cbWndExtra: 0,
                hInstance: instance,
                hIcon: nil,
                hCursor: nil,
                hbrBackground: Win32PaintResources.backgroundBrush,
                lpszMenuName: nil,
                lpszClassName: className,
                hIconSm: nil
            )

            _ = RegisterClassExW(&windowClass)
        }
    }

    /// Creates a child HWND and registers any associated action/drawing state.
    ///
    /// Implementation note:
    /// Many Win32 controls are child windows. The returned `HWND` represents
    /// the native control, not just a lightweight view object.
    private func createControl(
        className: String,
        title: String,
        style: DWORD,
        width: Int32,
        height: Int32,
        action: (() -> Void)?,
        button: ButtonRenderState? = nil,
        textField: WinTextField? = nil,
        toggle: WinToggle? = nil,
        pickerOption: PickerOptionState? = nil,
        textForegroundStyle: WinForegroundStyle? = nil
    ) -> HWND? {
        guard let window, let layout = layoutStack.last else {
            return nil
        }

        let controlID = nextControlID
        nextControlID += 1
        return withWideString(className) { controlClass in
            withWideString(title) { controlTitle in
                let control = CreateWindowExW(
                    0,
                    controlClass,
                    controlTitle,
                    style,
                    layout.x,
                    layout.y,
                    width,
                    height,
                    window,
                    HMENU(bitPattern: Int(controlID)),
                    instance,
                    nil
                )
                applyDisabledState(to: control, layout: layout)
                registerControlFrame(control, x: layout.x, y: layout.y, width: width, height: height)
                registerControlState(
                    controlID: controlID,
                    control: control,
                    action: action,
                    button: button,
                    textField: textField,
                    toggle: toggle,
                    pickerOption: pickerOption,
                    textForegroundStyle: textForegroundStyle
                )
                installHoverTrackingIfNeeded(
                    control: control,
                    isOwnerDrawn: button != nil || toggle != nil || pickerOption != nil
                )
                advance(width: width, height: height)
                return control
            }
        }
    }

    /// Installs child-control mouse tracking for owner-drawn controls.
    ///
    /// Implementation note:
    /// Some Win32 owner-draw paths do not reliably set `ODS_HOTLIGHT`, so hover
    /// is tracked by subclassing the child HWND and invalidating on
    /// `WM_MOUSEMOVE` / `WM_MOUSELEAVE`.
    private func installHoverTrackingIfNeeded(control: HWND?, isOwnerDrawn: Bool) {
        guard isOwnerDrawn else {
            return
        }

        installHoverTracking(for: control)
    }

    /// Stores the original unscrolled frame for a child control.
    private func registerControlFrame(_ control: HWND?, x: Int32, y: Int32, width: Int32, height: Int32) {
        guard let control else {
            return
        }

        let frame = ControlFrame(control: control, x: x, y: y, width: width, height: height)
        Win32ActionRegistry.controlFramesByHandle[UInt(bitPattern: control)] = frame
    }

    /// Creates a child static control that acts as a solid background panel.
    ///
    /// Implementation note:
    /// The panel is created before its child controls, so later child HWNDs sit
    /// above it in z-order. It is resized after the children reveal their
    /// consumed layout size.
    private func createBackgroundPanel(color: WinForegroundStyle, cornerRadius: Double, x: Int32, y: Int32) -> HWND? {
        guard let window else {
            return nil
        }

        let controlID = nextControlID
        nextControlID += 1
        return withWideString("STATIC") { controlClass in
            withWideString("") { controlTitle in
                let control = CreateWindowExW(
                    0,
                    controlClass,
                    controlTitle,
                    WS_CHILD | WS_VISIBLE | SS_OWNERDRAW,
                    x,
                    y,
                    1,
                    1,
                    window,
                    HMENU(bitPattern: Int(controlID)),
                    instance,
                    nil
                )
                if let control {
                    Win32ActionRegistry.backgrounds[UInt32(controlID)] = BackgroundRenderState(
                        color: color,
                        cornerRadius: max(0, Int32(cornerRadius))
                    )
                    registerControlFrame(control, x: x, y: y, width: 1, height: 1)
                }
                return control
            }
        }
    }

    /// Resizes a background panel after its child content has been placed.
    private func resizeBackgroundPanel(_ background: BackgroundLayoutState, width: Int32, height: Int32) {
        guard let control = background.control else {
            return
        }

        let resolvedWidth = max(1, width)
        let resolvedHeight = max(1, height)
        _ = MoveWindow(control, background.x, background.y, resolvedWidth, resolvedHeight, 1)
        registerControlFrame(control, x: background.x, y: background.y, width: resolvedWidth, height: resolvedHeight)
    }

    /// Creates a disabled owner-drawn panel that paints a border above content.
    ///
    /// Windows note:
    /// The panel is created after its children so the border remains visible.
    /// It is immediately disabled so normal mouse interaction continues to
    /// target the real controls underneath.
    private func createBorderPanel(_ border: BorderLayoutState, width: Int32, height: Int32) {
        guard let window else {
            return
        }

        let controlID = nextControlID
        nextControlID += 1
        let resolvedWidth = max(1, width)
        let resolvedHeight = max(1, height)
        let control = withWideString("STATIC") { controlClass in
            withWideString("") { controlTitle in
                CreateWindowExW(
                    0,
                    controlClass,
                    controlTitle,
                    WS_CHILD | WS_VISIBLE | SS_OWNERDRAW,
                    border.x,
                    border.y,
                    resolvedWidth,
                    resolvedHeight,
                    window,
                    HMENU(bitPattern: Int(controlID)),
                    instance,
                    nil
                )
            }
        }

        Win32ActionRegistry.borders[UInt32(controlID)] = BorderRenderState(
            color: border.color,
            width: border.width,
            cornerRadius: border.cornerRadius
        )
        registerControlFrame(control, x: border.x, y: border.y, width: resolvedWidth, height: resolvedHeight)
        _ = EnableWindow(control, 0)
    }

    /// Registers Swift state associated with a Win32 child control ID.
    private func registerControlState(
        controlID: UInt16,
        control: HWND?,
        action: (() -> Void)?,
        button: ButtonRenderState?,
        textField: WinTextField?,
        toggle: WinToggle?,
        pickerOption: PickerOptionState?,
        textForegroundStyle: WinForegroundStyle?
    ) {
        if let action {
            Win32ActionRegistry.actions[controlID] = action
        }
        if let button {
            Win32ActionRegistry.buttons[UInt32(controlID)] = button
        }
        if let textField {
            Win32ActionRegistry.textFields[controlID] = textField
        }
        if let toggle {
            Win32ActionRegistry.toggles[controlID] = toggle
            Win32ActionRegistry.toggleControls[controlID] = control
        }
        if let pickerOption {
            Win32ActionRegistry.pickerOptions[controlID] = pickerOption
            Win32ActionRegistry.pickerOptionControls[controlID] = control
        }
        if let textForegroundStyle, let control {
            Win32ActionRegistry.staticTextColorsByHandle[UInt(bitPattern: control)] = textForegroundStyle.win32Color
        }
    }

    /// Applies a cached Segoe UI font to a native control.
    private func applyFont(_ style: WinTextStyle, to control: HWND) {
        let font = fonts[style] ?? createFont(for: style)
        fonts[style] = font
        _ = SendMessageW(control, WM_SETFONT, WPARAM(UInt(bitPattern: font)), 1)
    }

    /// Applies a cue banner to an edit control when supported by Windows.
    private func setPlaceholder(_ prompt: String, for control: HWND) {
        guard !prompt.isEmpty else {
            return
        }

        withWideString(prompt) { promptPointer in
            _ = SendMessageW(control, EM_SETCUEBANNER, 0, LPARAM(Int(bitPattern: promptPointer)))
        }
    }

    /// Creates a GDI font for the given text style.
    ///
    /// Implementation note:
    /// Negative font heights request character height rather than cell height,
    /// which is the common Win32 path for UI fonts.
    private func createFont(for style: WinTextStyle) -> HFONT {
        let height = -Int32(style.size * 1.35)
        let weight = fontWeight(for: style.weight)

        return withWideString("Segoe UI") { faceName in
            CreateFontW(
                height,
                0,
                0,
                0,
                weight,
                0,
                0,
                0,
                DEFAULT_CHARSET,
                OUT_DEFAULT_PRECIS,
                CLIP_DEFAULT_PRECIS,
                CLEARTYPE_QUALITY,
                DEFAULT_PITCH | FF_DONTCARE,
                faceName
            )
        }
    }

    /// Maps framework font weights to Win32 numeric weights.
    private func fontWeight(for weight: WinFontWeight) -> Int32 {
        switch weight {
        case .regular:
            return FW_REGULAR
        case .semibold:
            return FW_SEMIBOLD
        case .bold:
            return FW_BOLD
        }
    }

    /// Advances the current layout context after placing an element.
    private func advance(width: Int32, height: Int32) {
        guard let layout = layoutStack.popLast() else {
            return
        }

        var updated = layout
        switch updated.axis {
        case .horizontal:
            updated.x += width + updated.spacing
            updated.maxCrossAxis = max(updated.maxCrossAxis, height)
        case .vertical:
            updated.y += height + updated.spacing
            updated.maxCrossAxis = max(updated.maxCrossAxis, width)
        }

        layoutStack.append(updated)
    }

    /// Runs the standard Win32 message loop.
    ///
    /// Apple developer note:
    /// This is the explicit event pump. Windows apps typically call
    /// `GetMessage`, `TranslateMessage`, and `DispatchMessage` until the window
    /// posts quit.
    private func runMessageLoop() {
        var message = MSG()
        while GetMessageW(&message, nil, 0, 0) > 0 {
            _ = TranslateMessage(&message)
            _ = DispatchMessageW(&message)
        }
    }

    /// Applies the current layout disabled state to a native child window.
    private func applyDisabledState(to control: HWND?, layout: LayoutState) {
        guard layout.isDisabled else {
            return
        }

        _ = EnableWindow(control, 0)
    }

    /// Returns the current frame width proposal, if one exists.
    private func proposedWidth(defaultingTo fallback: Int32) -> Int32 {
        layoutStack.last?.proposedWidth ?? fallback
    }

    /// Returns the current frame height proposal, if one exists.
    private func proposedHeight(defaultingTo fallback: Int32) -> Int32 {
        layoutStack.last?.proposedHeight ?? fallback
    }

    /// Converts optional `Double` dimensions to Win32 integer coordinates.
    private func int32(_ value: Double?) -> Int32? {
        guard let value else {
            return nil
        }

        return Int32(value)
    }

    /// Updates the scrollable content height after the initial render pass.
    private func updateContentHeight() {
        guard let root = layoutStack.last else {
            return
        }

        let size = consumedSize(of: root)
        Win32ActionRegistry.scrollState.contentHeight = root.originY + size.height + 34
    }

    /// Returns the size consumed by a completed direct-placement context.
    ///
    /// Implementation note:
    /// `maxCrossAxis` belongs to the axis perpendicular to advancement. Mixing
    /// it into both width and height made a fixed-width frame consume vertical
    /// space equal to its width, which created the large gaps seen in the demo.
    private func consumedSize(of layout: LayoutState) -> LayoutSize {
        switch layout.axis {
        case .horizontal:
            return LayoutSize(
                width: consumedDistance(from: layout.originX, to: layout.x, spacing: layout.spacing),
                height: layout.maxCrossAxis
            )
        case .vertical:
            return LayoutSize(
                width: layout.maxCrossAxis,
                height: consumedDistance(from: layout.originY, to: layout.y, spacing: layout.spacing)
            )
        }
    }

    /// Returns an axis distance without the trailing spacing after the last child.
    private func consumedDistance(from origin: Int32, to current: Int32, spacing: Int32) -> Int32 {
        let distance = current - origin
        guard distance > 0 else {
            return 0
        }

        return max(0, distance - spacing)
    }
}

/// Width and height consumed by a completed layout context.
private struct LayoutSize {
    var width: Int32
    var height: Int32
}

/// Native background panel waiting for its final child-driven size.
private struct BackgroundLayoutState {
    var control: HWND?
    var x: Int32
    var y: Int32
}

/// Border panel metadata waiting for child-driven size.
private struct BorderLayoutState {
    var x: Int32
    var y: Int32
    var color: WinForegroundStyle
    var width: Int32
    var cornerRadius: Int32
}

/// Current direct-placement layout context.
private struct LayoutState {
    var axis: WinAxis
    var originX: Int32
    var originY: Int32
    var x: Int32
    var y: Int32
    var spacing: Int32
    var maxCrossAxis: Int32 = 0
    var proposedWidth: Int32?
    var proposedHeight: Int32?
    var isDisabled: Bool

    init(
        axis: WinAxis,
        x: Int32,
        y: Int32,
        spacing: Int32,
        proposedWidth: Int32? = nil,
        proposedHeight: Int32? = nil,
        isDisabled: Bool = false
    ) {
        self.axis = axis
        self.originX = x
        self.originY = y
        self.x = x
        self.y = y
        self.spacing = spacing
        self.proposedWidth = proposedWidth
        self.proposedHeight = proposedHeight
        self.isDisabled = isDisabled
    }
}
#endif
