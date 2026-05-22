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
    case WM_CTLCOLORSTATIC:
        return handleStaticColor(wParam: wParam)
    case WM_DRAWITEM:
        return handleDrawItem(lParam: lParam)
    case WM_DESTROY:
        PostQuitMessage(0)
        return 0
    default:
        return DefWindowProcW(hwnd, message, wParam, lParam)
    }
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
private func handleStaticColor(wParam: WPARAM) -> LRESULT {
    _ = SetBkMode(HDC(bitPattern: wParam), TRANSPARENT)
    _ = SetTextColor(HDC(bitPattern: wParam), 0x00271811)
    return LRESULT(Int(bitPattern: Win32PaintResources.backgroundBrush))
}

/// Paints owner-drawn controls when Windows asks for them.
private func handleDrawItem(lParam: LPARAM) -> LRESULT {
    guard let drawItem = UnsafePointer<DRAWITEMSTRUCT>(bitPattern: lParam)?.pointee else {
        return 0
    }

    drawButton(drawItem)
    return 1
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

    let isOn = SendMessageW(control, BM_GETCHECK, 0, 0) == BST_CHECKED
    if isOn != toggle.isOn {
        toggle.isOn = isOn
        toggle.onChange?(isOn)
    }

    return true
}

/// Copies native radio-button selection into the matching `WinPicker`.
private func updatePicker(controlID: UInt16) -> Bool {
    guard let option = Win32ActionRegistry.pickerOptions[controlID] else {
        return false
    }

    if option.index != option.picker.selectedIndex {
        option.picker.selectedIndex = option.index
        option.picker.onChange?(option.index)
    }

    return true
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
