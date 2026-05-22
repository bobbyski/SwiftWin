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
    private var nextControlID: UInt16 = 100
    private var fonts: [WinTextStyle: HFONT] = [:]

    /// Creates native controls from a `WinWindow` and starts the message loop.
    func run(_ descriptor: WinWindow) {
        Win32ActionRegistry.reset()
        instance = GetModuleHandleW(nil)
        configureProcessDPIAwareness()
        initializeCommonControls()
        Win32PaintResources.backgroundBrush = CreateSolidBrush(0x00fbf8f7)
        registerWindowClass()
        createWindow(descriptor)
        layoutStack = [LayoutState(axis: .vertical, x: 36, y: 34, spacing: 12)]

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
        case let disabled as WinDisabled:
            beginDisabled(disabled.isDisabled)
            disabled.children.forEach(render)
            endDisabled()
        case let text as WinText:
            createText(text.value, style: text.style)
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
    @discardableResult
    private func createText(_ value: String, style: WinTextStyle) -> HWND? {
        if let control = createControl(
            className: "STATIC",
            title: value,
            style: WS_CHILD | WS_VISIBLE | SS_LEFT,
            width: proposedWidth(defaultingTo: max(220, Int32(value.count * 9 + 32))),
            height: proposedHeight(defaultingTo: style.size >= 20 ? 36 : 26),
            action: nil
        ) {
            applyFont(style, to: control)
            return control
        }

        return nil
    }

    /// Creates a native static text control backed by a dynamic provider.
    private func createDynamicText(_ text: WinDynamicText) {
        if let control = createText(text.value, style: text.style) {
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
            dwICC: ICC_BAR_CLASSES
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

    /// Formats the native value label for a slider.
    private func sliderDisplayText(_ slider: WinSlider) -> String {
        "\(slider.title): \(slider.value)"
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
        pickerOption: PickerOptionState? = nil
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
                    pickerOption: pickerOption
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

    /// Registers Swift state associated with a Win32 child control ID.
    private func registerControlState(
        controlID: UInt16,
        control: HWND?,
        action: (() -> Void)?,
        button: ButtonRenderState?,
        textField: WinTextField?,
        toggle: WinToggle?,
        pickerOption: PickerOptionState?
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
