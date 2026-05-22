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
        instance = GetModuleHandleW(nil)
        Win32PaintResources.backgroundBrush = CreateSolidBrush(0x00fbf8f7)
        registerWindowClass()
        createWindow(descriptor)
        layoutStack = [LayoutState(axis: .vertical, x: 36, y: 34, spacing: 12)]

        if let content = descriptor.content {
            render(content)
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
        case let text as WinText:
            createText(text.value, style: text.style)
        case let button as WinButton:
            createButton(button.title, style: button.style, action: button.action)
        case let textField as WinTextField:
            createTextField(textField)
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
        layoutStack.append(LayoutState(axis: axis, x: origin.x, y: origin.y, spacing: Int32(spacing)))
    }

    /// Pops a stack context and advances its parent by the consumed size.
    private func endStack() {
        guard layoutStack.count > 1, let child = layoutStack.popLast() else {
            return
        }

        let consumedWidth = max(child.maxCrossAxis, child.x - child.originX)
        let consumedHeight = max(child.maxCrossAxis, child.y - child.originY)
        advance(width: consumedWidth, height: consumedHeight)
    }

    /// Creates a native static text control.
    private func createText(_ value: String, style: WinTextStyle) {
        if let control = createControl(
            className: "STATIC",
            title: value,
            style: WS_CHILD | WS_VISIBLE | SS_LEFT,
            width: max(220, Int32(value.count * 9 + 32)),
            height: style.size >= 20 ? 36 : 26,
            action: nil
        ) {
            applyFont(style, to: control)
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
            width: max(buttonStyle == .primary ? 136 : 116, Int32(title.count * 9 + 48)),
            height: 40,
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
            width: 280,
            height: 32,
            action: nil,
            textField: field
        ) {
            applyFont(.body, to: control)
            setPlaceholder(field.prompt, for: control)
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
        textField: WinTextField? = nil
    ) -> HWND? {
        guard let window, let layout = layoutStack.last else {
            return nil
        }

        let controlID = nextControlID
        nextControlID += 1
        registerControlState(controlID: controlID, action: action, button: button, textField: textField)

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
                advance(width: width, height: height)
                return control
            }
        }
    }

    /// Registers Swift state associated with a Win32 child control ID.
    private func registerControlState(
        controlID: UInt16,
        action: (() -> Void)?,
        button: ButtonRenderState?,
        textField: WinTextField?
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

    init(axis: WinAxis, x: Int32, y: Int32, spacing: Int32) {
        self.axis = axis
        self.originX = x
        self.originY = y
        self.x = x
        self.y = y
        self.spacing = spacing
    }
}
#endif
