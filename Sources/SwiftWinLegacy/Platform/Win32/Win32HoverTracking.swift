#if os(Windows)
/// Installs a small child-window procedure that tracks hover state.
///
/// Windows oddity for Apple developers:
/// Child controls are real HWNDs and receive their own mouse messages. The
/// parent window procedure will not see those moves unless the control is
/// subclassed or the control forwards them.
func installHoverTracking(for control: HWND?) {
    guard let control else {
        return
    }

    let previous = SetWindowLongPtrW(control, GWLP_WNDPROC, swiftWinLegacyControlProc)
    guard let previous else {
        return
    }

    Win32ActionRegistry.originalControlProceduresByHandle[UInt(bitPattern: control)] = previous
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
    default:
        break
    }

    return callOriginalControlProcedure(hwnd: hwnd, message: message, wParam: wParam, lParam: lParam)
}

/// Marks a control hovered and requests a mouse-leave notification.
private func markControlHovered(_ control: HWND?) {
    guard let controlID = controlID(for: control),
          !Win32ActionRegistry.hoveredControlIDs.contains(controlID) else {
        return
    }

    Win32ActionRegistry.hoveredControlIDs.insert(controlID)
    requestMouseLeave(for: control)
    _ = InvalidateRect(control, nil, 1)
}

/// Marks a control no longer hovered.
private func markControlUnhovered(_ control: HWND?) {
    guard let controlID = controlID(for: control),
          Win32ActionRegistry.hoveredControlIDs.remove(controlID) != nil else {
        return
    }

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
