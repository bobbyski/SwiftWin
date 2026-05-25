#if os(Windows)
/// Window procedure for SwiftWinLegacy windows.
///
/// This is where Win32 messages are translated back into Swift behavior.
func swiftWinLegacyWindowProc(
    hwnd: HWND?,
    message: UINT,
    wParam: WPARAM,
    lParam: LPARAM
) -> LRESULT {
    switch message {
    case WM_KEYDOWN:
        if routeKeyboardCommand(key: wParam, focusedControl: nil) {
            return 0
        }
        return DefWindowProcW(hwnd, message, wParam, lParam)
    case WM_COMMAND:
        return handleCommand(wParam: wParam, lParam: lParam)
    case WM_NOTIFY:
        return handleNotify(lParam: lParam)
    case WM_HSCROLL:
        return handleHorizontalScroll(wParam: wParam, lParam: lParam)
    case WM_MOUSEWHEEL:
        return handleMouseWheel(hwnd: hwnd, wParam: wParam)
    case WM_SIZE:
        return handleWindowSize(hwnd: hwnd)
    case WM_CTLCOLOREDIT:
        return handleEditColor(wParam: wParam, lParam: lParam)
    case WM_CTLCOLORSTATIC:
        return handleStaticColor(wParam: wParam, lParam: lParam)
    case WM_DRAWITEM:
        return handleDrawItem(lParam: lParam)
    case WM_DESTROY:
        PostQuitMessage(0)
        return 0
    default:
        return DefWindowProcW(hwnd, message, wParam, lParam)
    }
}

/// Routes first-pass default and cancel keyboard commands.
///
/// Windows note:
/// `IsDialogMessageW` helps with focus traversal, but it does not invent
/// SwiftWin command semantics for a normal top-level window. This hook maps
/// Enter to the first primary button and Escape to an explicit Cancel button
/// when one exists.
func routeKeyboardCommand(key: WPARAM, focusedControl: HWND?) -> Bool {
    if routeKeyboardShortcut(key: key) {
        return true
    }

    if routeKeyboardScroll(key: key, focusedControl: focusedControl) {
        return true
    }

    guard !isMultilineEditor(focusedControl) else {
        return false
    }

    switch key {
    case VK_RETURN:
        guard let action = Win32ActionRegistry.defaultAction else {
            return false
        }
        action()
        return true
    case VK_ESCAPE:
        guard let action = Win32ActionRegistry.cancelAction else {
            return false
        }
        action()
        return true
    default:
        return false
    }
}

/// Routes keyboard scrolling for users without a wheel or touchpad gesture.
///
/// Windows note:
/// A plain Win32 child-window viewport does not gain Page Up/Page Down/Home/End
/// behavior automatically. SwiftWin treats these as scroll-view navigation when
/// focus is inside a scroll view, or when the demo has a single scroll view.
private func routeKeyboardScroll(key: WPARAM, focusedControl: HWND?) -> Bool {
    guard !hasCommandModifierDown(),
          let scrollID = scrollViewID(for: focusedControl),
          let state = Win32ActionRegistry.scrollViews[scrollID] else {
        return false
    }

    let pageStep = max(24, state.height - 32)
    switch key {
    case VK_PRIOR:
        applyScrollViewOffset(id: scrollID, requestedOffset: state.offset - pageStep)
        return true
    case VK_NEXT:
        applyScrollViewOffset(id: scrollID, requestedOffset: state.offset + pageStep)
        return true
    case VK_HOME:
        guard !isEditableControl(focusedControl) else {
            return false
        }
        applyScrollViewOffset(id: scrollID, requestedOffset: 0)
        return true
    case VK_END:
        guard !isEditableControl(focusedControl) else {
            return false
        }
        applyScrollViewOffset(id: scrollID, requestedOffset: state.contentHeight)
        return true
    default:
        return false
    }
}

/// Finds the most relevant scroll view for a focused control.
private func scrollViewID(for focusedControl: HWND?) -> UInt32? {
    if let focusedControl,
       let scrollID = Win32ActionRegistry.scrollViewIDByControlHandle[UInt(bitPattern: focusedControl)] {
        return scrollID
    }

    return firstScrollViewID()
}

/// Returns whether a focused control should keep text-style navigation keys.
private func isEditableControl(_ control: HWND?) -> Bool {
    guard let control else {
        return false
    }

    let controlID = UInt16(GetDlgCtrlID(control))
    return Win32ActionRegistry.textFields[controlID] != nil
        || Win32ActionRegistry.secureFields[controlID] != nil
        || Win32ActionRegistry.textEditors[controlID] != nil
        || Win32ActionRegistry.datePickers[controlID] != nil
}

/// Returns whether Control or Alt is currently held for command/menu shortcuts.
private func hasCommandModifierDown() -> Bool {
    isKeyDown(VK_CONTROL) || isKeyDown(VK_MENU)
}

/// Routes registered command shortcuts.
///
/// Windows note:
/// This is intentionally explicit. Unlike AppKit command routing, a plain Win32
/// window does not have a framework-level keyboard shortcut table unless the
/// app provides one.
private func routeKeyboardShortcut(key: WPARAM) -> Bool {
    for (shortcut, action) in Win32ActionRegistry.keyboardShortcuts {
        if keyboardShortcut(shortcut, matches: key) {
            action()
            return true
        }
    }

    return false
}

/// Returns whether the current key state matches a shortcut descriptor.
private func keyboardShortcut(_ shortcut: WinKeyboardShortcutDescriptor, matches key: WPARAM) -> Bool {
    guard shortcutVirtualKey(shortcut.key) == key else {
        return false
    }

    let requiresControl = shortcut.modifiers.contains(.control) || shortcut.modifiers.contains(.command)
    let requiresShift = shortcut.modifiers.contains(.shift)
    let requiresOption = shortcut.modifiers.contains(.option)
    return isKeyDown(VK_CONTROL) == requiresControl
        && isKeyDown(VK_SHIFT) == requiresShift
        && isKeyDown(VK_MENU) == requiresOption
}

/// Converts supported shortcut text into a Win32 virtual key code.
private func shortcutVirtualKey(_ key: String) -> WPARAM? {
    guard let unit = key.utf16.first else {
        return nil
    }

    if unit >= 65 && unit <= 90 {
        return WPARAM(unit)
    }
    if unit >= 97 && unit <= 122 {
        return WPARAM(unit - 32)
    }
    if unit >= 48 && unit <= 57 {
        return WPARAM(unit)
    }
    return nil
}

/// Returns whether a modifier key is currently down.
private func isKeyDown(_ virtualKey: Int32) -> Bool {
    GetKeyState(virtualKey) < 0
}

/// Returns whether the focused control is a multiline editor.
private func isMultilineEditor(_ control: HWND?) -> Bool {
    guard let control else {
        return false
    }

    return Win32ActionRegistry.textEditors[UInt16(GetDlgCtrlID(control))] != nil
}

/// Scrolls child HWND controls in response to mouse wheel or trackpad gestures.
///
/// Windows note:
/// A normal Win32 window is not scrollable unless the app explicitly handles
/// wheel messages and moves or repaints its content. This is our first default
/// window-level scroll path, before a real `ScrollView` exists.
private func handleMouseWheel(hwnd: HWND?, wParam: WPARAM) -> LRESULT {
    let delta = wheelDelta(from: wParam)
    let step = max(12, abs(delta) / 3)
    if let scrollID = firstScrollViewID() {
        let current = Win32ActionRegistry.scrollViews[scrollID]?.offset ?? 0
        applyScrollViewOffset(id: scrollID, requestedOffset: current - Int32(delta > 0 ? step : -step))
        return 0
    }

    let nextOffset = Win32ActionRegistry.scrollState.offset - Int32(delta > 0 ? step : -step)
    applyScrollOffset(nextOffset, window: hwnd)
    return 0
}

/// Re-clamps scroll offset after the user resizes the window.
private func handleWindowSize(hwnd: HWND?) -> LRESULT {
    applyScrollOffset(Win32ActionRegistry.scrollState.offset, window: hwnd)
    return 0
}

/// Routes `WM_COMMAND` notifications to Swift actions or text updates.
private func handleCommand(wParam: WPARAM, lParam: LPARAM) -> LRESULT {
    let controlID = UInt16(wParam & 0xffff)
    let notification = UInt16((wParam >> 16) & 0xffff)

    if notification == EN_CHANGE, let control = HWND(bitPattern: lParam) {
        if updateTextField(controlID: controlID, control: control) {
            return 0
        }
        if updateSecureField(controlID: controlID, control: control) {
            return 0
        }
        updateTextEditor(controlID: controlID, control: control)
        return 0
    }

    if notification == BN_CLICKED,
       let control = HWND(bitPattern: lParam),
       handleControlClick(controlID: controlID, control: control) {
        return 0
    }

    Win32ActionRegistry.actions[controlID]?()
    return 0
}

/// Routes `WM_NOTIFY` messages from common controls.
private func handleNotify(lParam: LPARAM) -> LRESULT {
    guard let header = UnsafePointer<NMHDR>(bitPattern: lParam)?.pointee else {
        return 0
    }

    if header.code == DTN_DATETIMECHANGE {
        updateDatePicker(controlID: UInt16(header.idFrom), lParam: lParam)
    }

    return 0
}

/// Updates checkbox/radio controls and returns whether the click was consumed.
private func handleControlClick(controlID: UInt16, control: HWND) -> Bool {
    let handledToggle = updateToggle(controlID: controlID, control: control)
    let handledPicker = updatePicker(controlID: controlID)
    let handledColorPicker = updateColorPicker(controlID: controlID, control: control)
    return handledToggle || handledPicker || handledColorPicker
}

/// Routes `WM_HSCROLL` notifications from native trackbar-backed sliders.
private func handleHorizontalScroll(wParam: WPARAM, lParam: LPARAM) -> LRESULT {
    guard let control = HWND(bitPattern: lParam),
          let state = Win32ActionRegistry.slidersByHandle[UInt(bitPattern: control)] else {
        return 0
    }

    let value = Int(SendMessageW(control, TBM_GETPOS, 0, 0))
    setSlider(state, value: value, control: control, notify: true)
    WinDynamicTextInvalidation.invalidateAll()
    return 0
}

/// Provides background colors for native edit controls.
///
/// Windows note:
/// Text fields are not owner-drawn. The supported lightweight customization
/// hook is `WM_CTLCOLOREDIT`, where the parent returns a brush used by the
/// child edit control. This gives keyboard focus a visible state without
/// replacing the native edit implementation. Date Time Pickers host an inner
/// edit child, so the check also recognizes controls whose parent is a
/// registered `WinDatePicker` HWND.
private func handleEditColor(wParam: WPARAM, lParam: LPARAM) -> LRESULT {
    guard let control = HWND(bitPattern: lParam),
          isEditableTextControl(control) else {
        return 0
    }

    guard isFocusedEditableTextControl(control) else {
        return LRESULT(Int(bitPattern: GetStockObject(WHITE_BRUSH)))
    }

    _ = SetBkColor(HDC(bitPattern: wParam), Win32PaintResources.focusedEditColor)
    _ = SetTextColor(HDC(bitPattern: wParam), WinForegroundStyle.primary.win32Color)
    return LRESULT(Int(bitPattern: Win32PaintResources.focusedEditBrush))
}

/// Returns whether a child HWND belongs to a SwiftWin editable text control.
private func isEditableTextControl(_ control: HWND) -> Bool {
    let controlID = UInt16(GetDlgCtrlID(control))
    return Win32ActionRegistry.textFields[controlID] != nil ||
        Win32ActionRegistry.secureFields[controlID] != nil ||
        Win32ActionRegistry.textEditors[controlID] != nil ||
        datePickerParent(for: control) != nil
}

/// Returns whether an editable text control currently has focus.
private func isFocusedEditableTextControl(_ control: HWND) -> Bool {
    let controlID = UInt32(GetDlgCtrlID(control))
    if Win32ActionRegistry.focusedControlIDs.contains(controlID) {
        return true
    }

    guard let parent = datePickerParent(for: control) else {
        return false
    }

    return Win32ActionRegistry.focusedControlIDs.contains(UInt32(GetDlgCtrlID(parent)))
}

/// Returns the registered date picker HWND that owns an internal edit child.
private func datePickerParent(for control: HWND) -> HWND? {
    guard let parent = GetParent(control) else {
        return nil
    }

    return Win32ActionRegistry.datePickerControls.values.contains { $0 == parent } ? parent : nil
}

/// Provides text colors for static controls.
private func handleStaticColor(wParam: WPARAM, lParam: LPARAM) -> LRESULT {
    _ = SetBkMode(HDC(bitPattern: wParam), TRANSPARENT)

    if let brush = staticBackgroundBrush(for: lParam) {
        return LRESULT(Int(bitPattern: brush))
    }

    if let brush = sliderBackgroundBrush(for: lParam) {
        return LRESULT(Int(bitPattern: brush))
    }

    let color = staticTextColor(for: lParam)
    _ = SetTextColor(HDC(bitPattern: wParam), color)

    if let brush = mutableTextSurfaceBrush(for: lParam) {
        return LRESULT(Int(bitPattern: brush))
    }

    return LRESULT(Int(bitPattern: staticTextBackgroundBrush()))
}

/// Returns a custom brush for background-panel static controls.
private func staticBackgroundBrush(for lParam: LPARAM) -> HBRUSH? {
    guard let control = HWND(bitPattern: lParam) else {
        return nil
    }

    return Win32ActionRegistry.staticBackgroundBrushesByHandle[UInt(bitPattern: control)]
}

/// Returns the stock trackbar background brush.
///
/// Windows note:
/// Trackbars ask through the same static-color message path as labels. Unlike
/// labels, they still need a real brush or they can paint black/blank
/// rectangles. This keeps the native slider visible while matching the default
/// SwiftWin panel surface.
private func sliderBackgroundBrush(for lParam: LPARAM) -> HBRUSH? {
    guard let control = HWND(bitPattern: lParam),
          Win32ActionRegistry.slidersByHandle[UInt(bitPattern: control)] != nil else {
        return nil
    }

    return Win32PaintResources.controlSurfaceBrush ?? Win32PaintResources.backgroundBrush
}

/// Returns a solid surface brush for labels whose text changes in place.
///
/// Windows note:
/// `NULL_BRUSH` is ideal for fixed labels over custom panels, but mutable
/// `STATIC` text can leave stale glyph pixels when Windows repaints only the
/// changed child. A matching surface brush preserves the polished look while
/// preventing text trails during state refresh.
private func mutableTextSurfaceBrush(for lParam: LPARAM) -> HBRUSH? {
    guard let control = HWND(bitPattern: lParam),
          Win32ActionRegistry.mutableTextSurfaceHandles.contains(UInt(bitPattern: control)) else {
        return nil
    }

    return Win32PaintResources.controlSurfaceBrush ?? Win32PaintResources.backgroundBrush
}

/// Returns the requested text color for one static child HWND.
private func staticTextColor(for lParam: LPARAM) -> DWORD {
    guard let control = HWND(bitPattern: lParam) else {
        return WinForegroundStyle.primary.win32Color
    }

    return Win32ActionRegistry.staticTextColorsByHandle[UInt(bitPattern: control)] ?? WinForegroundStyle.primary.win32Color
}

/// Returns the default brush for label backgrounds.
///
/// Windows note:
/// `SetBkMode(..., TRANSPARENT)` only affects how GDI draws the glyph
/// background. `WM_CTLCOLORSTATIC` still asks for a brush to paint the control
/// rectangle, so normal labels must return `NULL_BRUSH` to stay visually
/// transparent over panels and custom surfaces.
private func staticTextBackgroundBrush() -> HBRUSH? {
    GetStockObject(NULL_BRUSH)
}

/// Paints owner-drawn controls when Windows asks for them.
private func handleDrawItem(lParam: LPARAM) -> LRESULT {
    guard let drawItem = UnsafePointer<DRAWITEMSTRUCT>(bitPattern: lParam)?.pointee else {
        return 0
    }

    drawOwnerDrawnControl(drawItem)
    return 1
}

/// Applies a vertical scroll offset to all registered child controls.
private func applyScrollOffset(_ requestedOffset: Int32, window: HWND?) {
    let offset = clampedScrollOffset(requestedOffset, window: window)
    Win32ActionRegistry.scrollState.offset = offset

    redrawScrolledWindow(window)
    for frame in Win32ActionRegistry.controlFramesByHandle.values {
        if Win32ActionRegistry.scrollViewIDByControlHandle[UInt(bitPattern: frame.control)] != nil {
            continue
        }
        _ = MoveWindow(frame.control, frame.x, frame.y - offset, frame.width, frame.height, 1)
    }
    redrawScrolledWindow(window)
}

/// Applies a vertical scroll offset to one explicit scroll view.
func applyScrollViewOffset(id: UInt32, requestedOffset: Int32) {
    guard var state = Win32ActionRegistry.scrollViews[id] else {
        return
    }

    let oldOffset = state.offset
    let maximum = max(0, state.contentHeight - state.height)
    let offset = min(max(0, requestedOffset), maximum)
    state.offset = offset
    Win32ActionRegistry.scrollViews[id] = state
    let parent = parentWindow(for: state)

    redrawScrollViewViewport(state, parent: parent)

    for handle in state.controlHandles {
        guard let frame = Win32ActionRegistry.controlFramesByHandle[handle] else {
            continue
        }

        let oldY = frame.y - oldOffset
        let adjustedY = frame.y - offset
        let isVisible = adjustedY + frame.height > state.y && adjustedY < state.y + state.height
        redrawControlSlot(frame, y: oldY, parent: parent)
        setScrolledControlFrame(frame, y: adjustedY)
        _ = ShowWindow(frame.control, isVisible ? SW_SHOW : SW_HIDE)
        redrawControlSlot(frame, y: adjustedY, parent: parent)
    }

    updateScrollIndicator(state)
    redrawScrollViewViewport(state, parent: parent)
}

/// Returns the first explicit scroll view for the current prototype window.
private func firstScrollViewID() -> UInt32? {
    Win32ActionRegistry.scrollViews.keys.sorted().first
}

/// Erases and repaints the full client area before and after child HWND scrolling.
///
/// Windows note:
/// Moving child controls does not automatically erase every old pixel they
/// occupied. `RedrawWindow` with `RDW_ALLCHILDREN` is a blunt but reliable
/// prototype fix until a real `ScrollView` owns clipping and painting.
private func redrawScrolledWindow(_ window: HWND?) {
    _ = RedrawWindow(window, nil, nil, RDW_INVALIDATE | RDW_ERASE | RDW_ALLCHILDREN | RDW_UPDATENOW)
}

/// Moves a child control during scroll without asking Win32 to copy stale pixels.
///
/// Windows note:
/// `MoveWindow` can preserve bits from the previous location. That optimization
/// is visible as tearing when a scroll view is made from many child HWNDs, so
/// the scroll path uses `SWP_NOCOPYBITS` and drives repaint explicitly.
private func setScrolledControlFrame(_ frame: ControlFrame, y: Int32) {
    _ = SetWindowPos(
        frame.control,
        nil,
        frame.x,
        y,
        frame.width,
        frame.height,
        SWP_NOZORDER | SWP_NOACTIVATE | SWP_NOCOPYBITS
    )
}

/// Finds the native parent window that owns a scroll view's child controls.
private func parentWindow(for state: ScrollViewRuntimeState) -> HWND? {
    for handle in state.controlHandles {
        if let frame = Win32ActionRegistry.controlFramesByHandle[handle] {
            return GetParent(frame.control)
        }
    }

    return nil
}

/// Invalidates one old or new child-control slot inside a scroll viewport.
private func redrawControlSlot(_ frame: ControlFrame, y: Int32, parent: HWND?) {
    var rect = RECT(
        left: frame.x,
        top: y,
        right: frame.x + frame.width,
        bottom: y + frame.height
    )
    _ = RedrawWindow(parent, &rect, nil, RDW_INVALIDATE | RDW_ERASE | RDW_UPDATENOW)
}

/// Invalidates the complete viewport before and after moving scroll children.
private func redrawScrollViewViewport(_ state: ScrollViewRuntimeState, parent: HWND?) {
    var rect = RECT(
        left: state.x,
        top: state.y,
        right: state.x + state.width,
        bottom: state.y + state.height
    )
    _ = RedrawWindow(parent, &rect, nil, RDW_INVALIDATE | RDW_ERASE | RDW_ALLCHILDREN | RDW_UPDATENOW)
}

/// Sizes the visible scroll indicator thumb for the current viewport.
func scrollIndicatorThumbHeight(state: ScrollViewRuntimeState, trackHeight: Int32) -> Int32 {
    guard state.contentHeight > 0 else {
        return trackHeight
    }

    let visibleRatio = Double(state.height) / Double(state.contentHeight)
    return max(24, Int32(Double(trackHeight) * min(1.0, visibleRatio)))
}

/// Updates the lightweight scroll indicator to match the current offset.
private func updateScrollIndicator(_ state: ScrollViewRuntimeState) {
    guard let track = state.indicatorTrack,
          let thumb = state.indicatorThumb else {
        return
    }

    let trackWidth: Int32 = 6
    let trackInset: Int32 = 5
    let trackX = state.x + state.width - trackWidth - trackInset
    let trackY = state.y + trackInset
    let trackHeight = max(24, state.height - trackInset * 2)
    let thumbHeight = scrollIndicatorThumbHeight(state: state, trackHeight: trackHeight)
    let maximumOffset = max(1, state.contentHeight - state.height)
    let maximumThumbTravel = max(0, trackHeight - thumbHeight)
    let thumbY = trackY + Int32((Double(state.offset) / Double(maximumOffset)) * Double(maximumThumbTravel))
    let isScrollable = state.contentHeight > state.height

    _ = SetWindowPos(track, nil, trackX, trackY, trackWidth, trackHeight, SWP_NOZORDER | SWP_NOACTIVATE | SWP_NOCOPYBITS)
    _ = SetWindowPos(thumb, nil, trackX, thumbY, trackWidth, thumbHeight, SWP_NOZORDER | SWP_NOACTIVATE | SWP_NOCOPYBITS)
    _ = ShowWindow(track, isScrollable ? SW_SHOW : SW_HIDE)
    _ = ShowWindow(thumb, isScrollable ? SW_SHOW : SW_HIDE)
    _ = RedrawWindow(track, nil, nil, RDW_INVALIDATE | RDW_ERASE | RDW_UPDATENOW)
    _ = RedrawWindow(thumb, nil, nil, RDW_INVALIDATE | RDW_ERASE | RDW_UPDATENOW)
}

/// Clamps a requested scroll offset to the rendered content bounds.
private func clampedScrollOffset(_ requestedOffset: Int32, window: HWND?) -> Int32 {
    let maximum = max(0, Win32ActionRegistry.scrollState.contentHeight - clientHeight(of: window))
    return min(max(0, requestedOffset), maximum)
}

/// Returns the current client height for a window.
private func clientHeight(of window: HWND?) -> Int32 {
    var rect = RECT()
    guard GetClientRect(window, &rect) != 0 else {
        return 0
    }

    return max(0, rect.bottom - rect.top)
}

/// Extracts the signed wheel delta from a Win32 `WPARAM`.
private func wheelDelta(from wParam: WPARAM) -> Int32 {
    let highWord = UInt16((wParam >> 16) & 0xffff)
    return Int32(Int16(bitPattern: highWord))
}

/// Copies native edit-control text into the matching `WinTextField`.
private func updateTextField(controlID: UInt16, control: HWND) -> Bool {
    guard let textField = Win32ActionRegistry.textFields[controlID] else {
        return false
    }

    let value = text(from: control)
    guard value != textField.value else {
        return true
    }

    textField.value = value
    textField.onChange?(value)
    WinDynamicTextInvalidation.invalidateAll()
    return true
}

/// Copies native edit-control text into the matching `WinSecureField`.
private func updateSecureField(controlID: UInt16, control: HWND) -> Bool {
    guard let secureField = Win32ActionRegistry.secureFields[controlID] else {
        return false
    }

    let value = text(from: control)
    guard value != secureField.value else {
        return true
    }

    secureField.value = value
    secureField.onChange?(value)
    WinDynamicTextInvalidation.invalidateAll()
    return true
}

/// Copies native edit-control text into the matching `WinTextEditor`.
private func updateTextEditor(controlID: UInt16, control: HWND) {
    guard let textEditor = Win32ActionRegistry.textEditors[controlID] else {
        return
    }

    let value = text(from: control)
    guard value != textEditor.value else {
        return
    }

    textEditor.value = value
    textEditor.onChange?(value)
    WinDynamicTextInvalidation.invalidateAll()
}

/// Copies native checkbox state into the matching `WinToggle`.
private func updateToggle(controlID: UInt16, control: HWND) -> Bool {
    guard let toggle = Win32ActionRegistry.toggles[controlID] else {
        return false
    }

    toggle.isOn.toggle()
    _ = InvalidateRect(control, nil, 1)
    toggle.onChange?(toggle.isOn)
    WinDynamicTextInvalidation.invalidateAll()

    return true
}

/// Copies native radio-button selection into the matching `WinPicker`.
private func updatePicker(controlID: UInt16) -> Bool {
    guard let option = Win32ActionRegistry.pickerOptions[controlID] else {
        return false
    }

    if option.index != option.picker.selectedIndex {
        option.picker.selectedIndex = option.index
        invalidatePickerOptions(for: option.picker)
        option.picker.onChange?(option.index)
        WinDynamicTextInvalidation.invalidateAll()
    }

    return true
}

/// Opens the native common color dialog for a color picker.
///
/// Windows note for Apple developers:
/// Win32's color picker is a modal Common Dialog, not an inline popover. It
/// reports colors as `COLORREF`, which uses `0x00bbggrr` byte ordering.
private func updateColorPicker(controlID: UInt16, control: HWND) -> Bool {
    guard let colorPicker = Win32ActionRegistry.colorPickers[controlID] else {
        return false
    }

    guard let color = chooseColor(initialColor: colorPicker.color, owner: GetParent(control)) else {
        return true
    }

    colorPicker.color = color
    _ = InvalidateRect(control, nil, 1)
    colorPicker.onChange?(colorPicker.color)
    WinDynamicTextInvalidation.invalidateAll()
    return true
}

/// Presents the Windows common color dialog.
private func chooseColor(initialColor: WinForegroundStyle, owner: HWND?) -> WinForegroundStyle? {
    var customColors = normalizedCustomColors()
    var chooseColor = CHOOSECOLORW(
        lStructSize: DWORD(MemoryLayout<CHOOSECOLORW>.size),
        hwndOwner: owner,
        hInstance: nil,
        rgbResult: initialColor.win32Color,
        lpCustColors: nil,
        Flags: CC_RGBINIT | CC_FULLOPEN,
        lCustData: 0,
        lpfnHook: nil,
        lpTemplateName: nil
    )

    let accepted = customColors.withUnsafeMutableBufferPointer { buffer in
        chooseColor.lpCustColors = buffer.baseAddress
        return ChooseColorW(&chooseColor) != 0
    }

    Win32ActionRegistry.customColorDialogValues = customColors
    guard accepted else {
        return nil
    }

    return foregroundStyle(from: chooseColor.rgbResult)
}

/// Returns the 16 custom color slots required by `ChooseColorW`.
private func normalizedCustomColors() -> [COLORREF] {
    var colors = Win32ActionRegistry.customColorDialogValues
    while colors.count < 16 {
        colors.append(0x00ffffff)
    }
    if colors.count > 16 {
        colors = Array(colors.prefix(16))
    }
    return colors
}

/// Converts a Win32 `COLORREF` into a SwiftWin RGB style.
private func foregroundStyle(from color: COLORREF) -> WinForegroundStyle {
    WinForegroundStyle(
        red: UInt8(color & 0x000000ff),
        green: UInt8((color & 0x0000ff00) >> 8),
        blue: UInt8((color & 0x00ff0000) >> 16)
    )
}

/// Copies native date picker state into the matching `WinDatePicker`.
private func updateDatePicker(controlID: UInt16, lParam: LPARAM) {
    guard let datePicker = Win32ActionRegistry.datePickers[controlID],
          let change = UnsafePointer<NMDATETIMECHANGE>(bitPattern: lParam)?.pointee else {
        return
    }

    let value = winDate(from: change.st)
    guard value != datePicker.date else {
        return
    }

    datePicker.date = value
    datePicker.onChange?(value)
    WinDynamicTextInvalidation.invalidateAll()
}

/// Redraws all native option buttons for a picker.
private func invalidatePickerOptions(for picker: WinPicker) {
    for (controlID, option) in Win32ActionRegistry.pickerOptions where option.picker === picker {
        guard let control = Win32ActionRegistry.pickerOptionControls[controlID] else {
            continue
        }
        _ = InvalidateRect(control, nil, 1)
    }
}

/// Reads UTF-16 text from a Win32 control.
private func text(from control: HWND) -> String {
    let length = max(0, GetWindowTextLengthW(control))
    var buffer = Array(repeating: UInt16(0), count: Int(length) + 1)
    let copied = buffer.withUnsafeMutableBufferPointer { pointer in
        GetWindowTextW(control, pointer.baseAddress, Int32(pointer.count))
    }
    return String(decoding: buffer.prefix(Int(copied)), as: UTF16.self)
}
#endif
