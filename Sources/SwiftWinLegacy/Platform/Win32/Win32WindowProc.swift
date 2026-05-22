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

    Win32ActionRegistry.actions[controlID]?()
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
