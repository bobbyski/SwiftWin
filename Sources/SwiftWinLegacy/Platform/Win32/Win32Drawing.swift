#if os(Windows)
/// Paints an owner-drawn button.
///
/// Implementation note:
/// GDI color values are `COLORREF` in `0x00bbggrr` order, which looks odd if
/// you are used to CSS/AppKit-style RGB notation.
func drawButton(_ item: DRAWITEMSTRUCT) {
    guard let deviceContext = item.hDC,
          let button = Win32ActionRegistry.buttons[item.CtlID] else {
        return
    }

    let isPressed = (item.itemState & ODS_SELECTED) != 0
    let isFocused = (item.itemState & ODS_FOCUS) != 0
    let palette = buttonPalette(for: button.style, isPressed: isPressed)
    paintButtonBackground(item.rcItem, in: deviceContext, palette: palette, isPressed: isPressed, isFocused: isFocused)
    paintButtonTitle(button.title, in: item.rcItem, deviceContext: deviceContext, palette: palette, isPressed: isPressed)
}

/// Paints the rounded button surface.
private func paintButtonBackground(
    _ rect: RECT,
    in deviceContext: HDC,
    palette: ButtonPalette,
    isPressed: Bool,
    isFocused: Bool
) {
    let fillBrush = CreateSolidBrush(palette.fill)
    let borderPen = CreatePen(PS_SOLID, isFocused ? 2 : 1, palette.border)
    let oldBrush = SelectObject(deviceContext, fillBrush)
    let oldPen = SelectObject(deviceContext, borderPen)
    let offset: Int32 = isPressed ? 1 : 0

    _ = RoundRect(
        deviceContext,
        rect.left + offset,
        rect.top + offset,
        rect.right - 1 + offset,
        rect.bottom - 1 + offset,
        10,
        10
    )

    restore(object: oldBrush, into: deviceContext)
    restore(object: oldPen, into: deviceContext)
    _ = DeleteObject(fillBrush)
    _ = DeleteObject(borderPen)
}

/// Restores a previously selected GDI object.
private func restore(object: HGDIOBJ?, into deviceContext: HDC) {
    if let object {
        _ = SelectObject(deviceContext, object)
    }
}

/// Paints centered button text.
private func paintButtonTitle(
    _ title: String,
    in rect: RECT,
    deviceContext: HDC,
    palette: ButtonPalette,
    isPressed: Bool
) {
    _ = SetBkMode(deviceContext, TRANSPARENT)
    _ = SetTextColor(deviceContext, palette.text)

    var textRect = rect
    let offset: Int32 = isPressed ? 1 : 0
    textRect.left += 12 + offset
    textRect.right -= 12 - offset
    textRect.top += offset
    textRect.bottom += offset

    withWideString(title) { title in
        _ = DrawTextW(deviceContext, title, -1, &textRect, DT_CENTER | DT_VCENTER | DT_SINGLELINE)
    }
}

/// Returns owner-draw colors for the current button state.
private func buttonPalette(for style: WinButtonStyle, isPressed: Bool) -> ButtonPalette {
    switch style {
    case .primary:
        return ButtonPalette(fill: isPressed ? 0x00c8521d : 0x00eb6325, border: isPressed ? 0x00b84818 : 0x00d95b20, text: 0x00ffffff)
    case .secondary:
        return ButtonPalette(fill: isPressed ? 0x00f0ecea : 0x00ffffff, border: 0x00ddd4cf, text: 0x00271811)
    }
}

/// Owner-draw color palette.
private struct ButtonPalette {
    var fill: DWORD
    var border: DWORD
    var text: DWORD
}
#endif
