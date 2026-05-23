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
    case WM_COMMAND:
        return handleCommand(wParam: wParam, lParam: lParam)
    case WM_HSCROLL:
        return handleHorizontalScroll(wParam: wParam, lParam: lParam)
    case WM_MOUSEWHEEL:
        return handleMouseWheel(hwnd: hwnd, wParam: wParam)
    case WM_SIZE:
        return handleWindowSize(hwnd: hwnd)
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

/// Scrolls child HWND controls in response to mouse wheel or trackpad gestures.
///
/// Windows note:
/// A normal Win32 window is not scrollable unless the app explicitly handles
/// wheel messages and moves or repaints its content. This is our first default
/// window-level scroll path, before a real `ScrollView` exists.
private func handleMouseWheel(hwnd: HWND?, wParam: WPARAM) -> LRESULT {
    let delta = wheelDelta(from: wParam)
    let step = max(12, abs(delta) / 3)
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
        updateTextField(controlID: controlID, control: control)
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

/// Updates checkbox/radio controls and returns whether the click was consumed.
private func handleControlClick(controlID: UInt16, control: HWND) -> Bool {
    let handledToggle = updateToggle(controlID: controlID, control: control)
    let handledPicker = updatePicker(controlID: controlID)
    return handledToggle || handledPicker
}

/// Routes `WM_HSCROLL` notifications from native trackbar-backed sliders.
private func handleHorizontalScroll(wParam: WPARAM, lParam: LPARAM) -> LRESULT {
    guard let control = HWND(bitPattern: lParam),
          let state = Win32ActionRegistry.slidersByHandle[UInt(bitPattern: control)] else {
        return 0
    }

    let value = Int(SendMessageW(control, TBM_GETPOS, 0, 0))
    set(sliderState: state, value: value, control: control)
    return 0
}

/// Provides text colors for static controls.
private func handleStaticColor(wParam: WPARAM, lParam: LPARAM) -> LRESULT {
    if let brush = staticBackgroundBrush(for: lParam) {
        return LRESULT(Int(bitPattern: brush))
    }

    let color = staticTextColor(for: lParam)
    _ = SetBkMode(HDC(bitPattern: wParam), TRANSPARENT)
    _ = SetTextColor(HDC(bitPattern: wParam), color)
    return LRESULT(Int(bitPattern: Win32PaintResources.backgroundBrush))
}

/// Returns a custom brush for background-panel static controls.
private func staticBackgroundBrush(for lParam: LPARAM) -> HBRUSH? {
    guard let control = HWND(bitPattern: lParam) else {
        return nil
    }

    return Win32ActionRegistry.staticBackgroundBrushesByHandle[UInt(bitPattern: control)]
}

/// Returns the requested text color for one static child HWND.
private func staticTextColor(for lParam: LPARAM) -> DWORD {
    guard let control = HWND(bitPattern: lParam) else {
        return WinForegroundStyle.primary.win32Color
    }

    return Win32ActionRegistry.staticTextColorsByHandle[UInt(bitPattern: control)] ?? WinForegroundStyle.primary.win32Color
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

    for frame in Win32ActionRegistry.controlFramesByHandle.values {
        _ = MoveWindow(frame.control, frame.x, frame.y - offset, frame.width, frame.height, 1)
    }
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
private func updateTextField(controlID: UInt16, control: HWND) {
    guard let textField = Win32ActionRegistry.textFields[controlID] else {
        return
    }

    let value = text(from: control)
    guard value != textField.value else {
        return
    }

    textField.value = value
    textField.onChange?(value)
}

/// Copies native checkbox state into the matching `WinToggle`.
private func updateToggle(controlID: UInt16, control: HWND) -> Bool {
    guard let toggle = Win32ActionRegistry.toggles[controlID] else {
        return false
    }

    toggle.isOn.toggle()
    _ = InvalidateRect(control, nil, 1)
    toggle.onChange?(toggle.isOn)

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
    }

    return true
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

/// Stores a slider value and mirrors it back to the native controls.
private func set(sliderState: SliderRenderState, value: Int, control: HWND) {
    let slider = sliderState.slider
    let clamped = min(max(value, slider.minimum), slider.maximum)
    guard clamped != slider.value else {
        return
    }

    slider.value = clamped
    updateSliderLabel(sliderState.label, slider: slider)
    _ = SendMessageW(control, TBM_SETPOS, 1, LPARAM(clamped))
    slider.onChange?(clamped)
    WinDynamicTextInvalidation.invalidateAll()
}

/// Updates the static text label owned by a slider.
private func updateSliderLabel(_ label: HWND, slider: WinSlider) {
    withWideString("\(slider.title): \(slider.value)") { text in
        _ = SetWindowTextW(label, text)
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
