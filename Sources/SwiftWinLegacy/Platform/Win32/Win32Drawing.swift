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

/// Routes an owner-drawn control to its specific painter.
func drawOwnerDrawnControl(_ item: DRAWITEMSTRUCT) {
    if Win32ActionRegistry.buttons[item.CtlID] != nil {
        drawButton(item)
        return
    }

    if Win32ActionRegistry.toggles[UInt16(item.CtlID)] != nil {
        drawToggle(item)
        return
    }

    if Win32ActionRegistry.pickerOptions[UInt16(item.CtlID)] != nil {
        drawPickerOption(item)
    }
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

/// Paints an owner-drawn checkbox row.
private func drawToggle(_ item: DRAWITEMSTRUCT) {
    guard let deviceContext = item.hDC,
          let toggle = Win32ActionRegistry.toggles[UInt16(item.CtlID)] else {
        return
    }

    paintToggleBox(in: item.rcItem, deviceContext: deviceContext, isOn: toggle.isOn)
    paintToggleTitle(toggle.title, in: item.rcItem, deviceContext: deviceContext)
}

/// Paints the custom checkbox square.
private func paintToggleBox(in rect: RECT, deviceContext: HDC, isOn: Bool) {
    let box = RECT(left: rect.left + 1, top: rect.top + 6, right: rect.left + 21, bottom: rect.top + 26)
    let fill = CreateSolidBrush(isOn ? 0x00eb6325 : 0x00ffffff)
    let border = CreatePen(PS_SOLID, 1, isOn ? 0x00d95b20 : 0x00cfc7c2)
    let oldBrush = SelectObject(deviceContext, fill)
    let oldPen = SelectObject(deviceContext, border)

    _ = RoundRect(deviceContext, box.left, box.top, box.right, box.bottom, 5, 5)
    restore(object: oldBrush, into: deviceContext)
    restore(object: oldPen, into: deviceContext)
    _ = DeleteObject(fill)
    _ = DeleteObject(border)

    if isOn {
        paintCheckmark(in: box, deviceContext: deviceContext)
    }
}

/// Paints a compact check mark.
private func paintCheckmark(in rect: RECT, deviceContext: HDC) {
    let pen = CreatePen(PS_SOLID, 2, 0x00ffffff)
    let oldPen = SelectObject(deviceContext, pen)
    _ = MoveToEx(deviceContext, rect.left + 5, rect.top + 10, nil)
    _ = LineTo(deviceContext, rect.left + 9, rect.top + 14)
    _ = LineTo(deviceContext, rect.left + 15, rect.top + 6)
    restore(object: oldPen, into: deviceContext)
    _ = DeleteObject(pen)
}

/// Paints the text portion of a toggle row.
private func paintToggleTitle(_ title: String, in rect: RECT, deviceContext: HDC) {
    _ = SetBkMode(deviceContext, TRANSPARENT)
    _ = SetTextColor(deviceContext, 0x00271811)

    var textRect = rect
    textRect.left += 30
    textRect.right -= 4

    withWideString(title) { title in
        _ = DrawTextW(deviceContext, title, -1, &textRect, DT_VCENTER | DT_SINGLELINE)
    }
}

/// Paints an owner-drawn segmented picker option.
private func drawPickerOption(_ item: DRAWITEMSTRUCT) {
    guard let deviceContext = item.hDC,
          let option = Win32ActionRegistry.pickerOptions[UInt16(item.CtlID)] else {
        return
    }

    let isSelected = option.index == option.picker.selectedIndex
    paintPickerOptionBackground(item.rcItem, deviceContext: deviceContext, isSelected: isSelected)
    paintPickerOptionTitle(option.picker.options[option.index], in: item.rcItem, deviceContext: deviceContext, isSelected: isSelected)
}

/// Paints a pill-style picker option background.
private func paintPickerOptionBackground(_ rect: RECT, deviceContext: HDC, isSelected: Bool) {
    let fill = CreateSolidBrush(isSelected ? 0x00f7e6dc : 0x00ffffff)
    let border = CreatePen(PS_SOLID, 1, isSelected ? 0x00eb6325 : 0x00ddd4cf)
    let oldBrush = SelectObject(deviceContext, fill)
    let oldPen = SelectObject(deviceContext, border)

    _ = RoundRect(deviceContext, rect.left, rect.top + 1, rect.right - 1, rect.bottom - 1, 12, 12)
    restore(object: oldBrush, into: deviceContext)
    restore(object: oldPen, into: deviceContext)
    _ = DeleteObject(fill)
    _ = DeleteObject(border)
}

/// Paints picker option text.
private func paintPickerOptionTitle(_ title: String, in rect: RECT, deviceContext: HDC, isSelected: Bool) {
    _ = SetBkMode(deviceContext, TRANSPARENT)
    _ = SetTextColor(deviceContext, isSelected ? 0x00b84818 : 0x00271811)

    var textRect = rect
    textRect.left += 12
    textRect.right -= 12

    withWideString(title) { title in
        _ = DrawTextW(deviceContext, title, -1, &textRect, DT_CENTER | DT_VCENTER | DT_SINGLELINE)
    }
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
