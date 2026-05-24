#if os(Windows)
/// Installs a small child-window procedure that tracks focus state.
///
/// Windows oddity for Apple developers:
/// Child controls are real HWNDs and receive their own keyboard/focus
/// messages. The parent window procedure will not see those changes unless
/// the control is subclassed or the control forwards them.
func installControlTracking(for control: HWND?) {
    guard let control else {
        return
    }

    let key = UInt(bitPattern: control)
    guard Win32ActionRegistry.originalControlProceduresByHandle[key] == nil else {
        return
    }

    let previous = SetWindowLongPtrW(control, GWLP_WNDPROC, swiftWinLegacyControlProc)
    guard let previous else {
        return
    }

    Win32ActionRegistry.originalControlProceduresByHandle[key] = previous
}

/// Installs tracking for owner-drawn controls that need hover repainting.
func installHoverTracking(for control: HWND?) {
    installControlTracking(for: control)
}

/// Window procedure used by owner-drawn child controls.
func swiftWinLegacyControlProc(
    hwnd: HWND?,
    message: UINT,
    wParam: WPARAM,
    lParam: LPARAM
) -> LRESULT {
    switch message {
    case WM_MOUSEMOVE:
        markControlHovered(hwnd)
    case WM_MOUSELEAVE:
        markControlUnhovered(hwnd)
    case WM_SETFOCUS:
        markControlFocused(hwnd)
    case WM_KILLFOCUS:
        markControlUnfocused(hwnd)
    case WM_KEYDOWN:
        if wParam == VK_TAB, moveFocusFromTextEditor(hwnd) {
            return 0
        }
        if routeKeyboardCommand(key: wParam, focusedControl: hwnd) {
            return 0
        }
    default:
        break
    }

    return callOriginalControlProcedure(hwnd: hwnd, message: message, wParam: wParam, lParam: lParam)
}

/// Marks a control focused so owner-drawn paint can show keyboard location.
private func markControlFocused(_ control: HWND?) {
    guard let controlID = controlID(for: control),
          Win32ActionRegistry.focusedControlIDs.insert(controlID).inserted else {
        return
    }

    _ = InvalidateRect(control, nil, 1)
    _ = RedrawWindow(control, nil, nil, RDW_INVALIDATE | RDW_ERASE | RDW_UPDATENOW)
}

/// Clears focus state from a control and repaints it.
private func markControlUnfocused(_ control: HWND?) {
    guard let controlID = controlID(for: control),
          Win32ActionRegistry.focusedControlIDs.remove(controlID) != nil else {
        return
    }

    _ = InvalidateRect(control, nil, 1)
    _ = RedrawWindow(control, nil, nil, RDW_INVALIDATE | RDW_ERASE | RDW_UPDATENOW)
}

/// Lets multiline text editors use Tab for focus traversal.
///
/// Windows note:
/// Multiline `EDIT` controls can consume navigation keys. For now SwiftWin
/// keeps Tab as app traversal and leaves literal tab insertion for a later
/// editor-specific option.
private func moveFocusFromTextEditor(_ control: HWND?) -> Bool {
    guard let control,
          let controlID = controlID(for: control),
          Win32ActionRegistry.textEditors[UInt16(controlID)] != nil else {
        return false
    }

    let previous: BOOL = GetKeyState(VK_SHIFT) < 0 ? 1 : 0
    guard let next = GetNextDlgTabItem(GetParent(control), control, previous) else {
        return false
    }

    _ = SetFocus(next)
    return true
}

/// Marks a control hovered and requests a mouse-leave notification.
private func markControlHovered(_ control: HWND?) {
    guard let controlID = controlID(for: control),
          !Win32ActionRegistry.hoveredControlIDs.contains(controlID) else {
        return
    }

    Win32ActionRegistry.hoveredControlIDs.insert(controlID)
    Win32ActionRegistry.hoverActions[controlID]?(true)
    requestMouseLeave(for: control)
    _ = InvalidateRect(control, nil, 1)
}

/// Marks a control no longer hovered.
private func markControlUnhovered(_ control: HWND?) {
    guard let controlID = controlID(for: control),
          Win32ActionRegistry.hoveredControlIDs.remove(controlID) != nil else {
        return
    }

    Win32ActionRegistry.hoverActions[controlID]?(false)
    _ = InvalidateRect(control, nil, 1)
}

/// Requests `WM_MOUSELEAVE` for a child control.
private func requestMouseLeave(for control: HWND?) {
    var event = TRACKMOUSEEVENT(
        cbSize: DWORD(MemoryLayout<TRACKMOUSEEVENT>.size),
        dwFlags: TME_LEAVE,
        hwndTrack: control,
        dwHoverTime: HOVER_DEFAULT
    )
    _ = TrackMouseEvent(&event)
}

/// Returns the control ID assigned by `CreateWindowExW`.
private func controlID(for control: HWND?) -> UInt32? {
    guard let control else {
        return nil
    }

    return UInt32(GetDlgCtrlID(control))
}

/// Forwards messages to the original child-window procedure.
private func callOriginalControlProcedure(
    hwnd: HWND?,
    message: UINT,
    wParam: WPARAM,
    lParam: LPARAM
) -> LRESULT {
    guard let hwnd,
          let previous = Win32ActionRegistry.originalControlProceduresByHandle[UInt(bitPattern: hwnd)] else {
        return DefWindowProcW(hwnd, message, wParam, lParam)
    }

    return CallWindowProcW(previous, hwnd, message, wParam, lParam)
}
#endif
