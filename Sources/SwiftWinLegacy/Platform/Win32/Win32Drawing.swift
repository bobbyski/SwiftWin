#if os(Windows)
/// Converts SwiftWin semantic foreground color to Win32 `COLORREF`.
///
/// Implementation note:
/// GDI color values are `COLORREF` in `0x00bbggrr` order, which looks odd if
/// you are used to CSS/AppKit-style RGB notation.
extension WinForegroundStyle {
    var win32Color: DWORD {
        DWORD(red) | (DWORD(green) << 8) | (DWORD(blue) << 16)
    }
}

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
    let isDisabled = (item.itemState & ODS_DISABLED) != 0
    let isHovered = isHot(item)
    let palette = buttonPalette(for: button.style, isPressed: isPressed, isHovered: isHovered, isDisabled: isDisabled)
    if let role = button.segmentRole {
        paintSegmentBackground(item.rcItem, in: deviceContext, role: role, palette: palette, isPressed: isPressed, isFocused: isFocused)
    } else {
        paintButtonBackground(item.rcItem, in: deviceContext, palette: palette, isPressed: isPressed, isFocused: isFocused)
    }
    paintButtonTitle(button.title, in: item.rcItem, deviceContext: deviceContext, palette: palette, isPressed: isPressed)
}

/// Routes an owner-drawn control to its specific painter.
func drawOwnerDrawnControl(_ item: DRAWITEMSTRUCT) {
    if Win32ActionRegistry.buttons[item.CtlID] != nil {
        drawButton(item)
        return
    }

    if Win32ActionRegistry.stepperValues[item.CtlID] != nil {
        drawStepperValue(item)
        return
    }

    if Win32ActionRegistry.toggles[UInt16(item.CtlID)] != nil {
        drawToggle(item)
        return
    }

    if Win32ActionRegistry.pickerOptions[UInt16(item.CtlID)] != nil {
        drawPickerOption(item)
        return
    }

    if Win32ActionRegistry.backgrounds[item.CtlID] != nil {
        drawBackground(item)
        return
    }

    if Win32ActionRegistry.borders[item.CtlID] != nil {
        drawBorder(item)
        return
    }

    if Win32ActionRegistry.separators[item.CtlID] != nil {
        drawSeparator(item)
    }
}

/// Paints the value segment in an integrated stepper.
private func drawStepperValue(_ item: DRAWITEMSTRUCT) {
    guard let deviceContext = item.hDC,
          let value = Win32ActionRegistry.stepperValues[item.CtlID] else {
        return
    }

    let palette = ButtonPalette(fill: 0x00ffffff, border: 0x00ddd4cf, text: 0x00271811)
    paintSegmentBackground(item.rcItem, in: deviceContext, role: .center, palette: palette, isPressed: false, isFocused: false)
    paintSegmentText("\(value.stepper.value)", in: item.rcItem, deviceContext: deviceContext, color: palette.text)
}

/// Paints a noninteractive background panel.
private func drawBackground(_ item: DRAWITEMSTRUCT) {
    guard let deviceContext = item.hDC,
          let background = Win32ActionRegistry.backgrounds[item.CtlID] else {
        return
    }

    let brush = CreateSolidBrush(background.color.win32Color)
    let pen = CreatePen(PS_SOLID, 1, background.color.win32Color)
    let oldBrush = SelectObject(deviceContext, brush)
    let oldPen = SelectObject(deviceContext, pen)
    let diameter = cornerDiameter(background.cornerRadius)

    _ = RoundRect(
        deviceContext,
        item.rcItem.left,
        item.rcItem.top,
        item.rcItem.right - 1,
        item.rcItem.bottom - 1,
        diameter,
        diameter
    )

    restore(object: oldBrush, into: deviceContext)
    restore(object: oldPen, into: deviceContext)
    _ = DeleteObject(brush)
    _ = DeleteObject(pen)
}

/// Paints a noninteractive border panel.
private func drawBorder(_ item: DRAWITEMSTRUCT) {
    guard let deviceContext = item.hDC,
          let border = Win32ActionRegistry.borders[item.CtlID] else {
        return
    }

    let pen = CreatePen(PS_SOLID, border.width, border.color.win32Color)
    let nullBrush = GetStockObject(NULL_BRUSH)
    let oldBrush = SelectObject(deviceContext, nullBrush)
    let oldPen = SelectObject(deviceContext, pen)
    let inset = max(0, border.width)
    let diameter = cornerDiameter(border.cornerRadius)

    _ = RoundRect(
        deviceContext,
        item.rcItem.left + inset / 2,
        item.rcItem.top + inset / 2,
        item.rcItem.right - inset,
        item.rcItem.bottom - inset,
        diameter,
        diameter
    )

    restore(object: oldBrush, into: deviceContext)
    restore(object: oldPen, into: deviceContext)
    _ = DeleteObject(pen)
}

/// Paints a separator line.
private func drawSeparator(_ item: DRAWITEMSTRUCT) {
    guard let deviceContext = item.hDC,
          let separator = Win32ActionRegistry.separators[item.CtlID] else {
        return
    }

    let pen = CreatePen(PS_SOLID, separator.thickness, separator.color.win32Color)
    let oldPen = SelectObject(deviceContext, pen)

    switch separator.axis {
    case .horizontal:
        let y = item.rcItem.top + max(1, (item.rcItem.bottom - item.rcItem.top) / 2)
        _ = MoveToEx(deviceContext, item.rcItem.left, y, nil)
        _ = LineTo(deviceContext, item.rcItem.right, y)
    case .vertical:
        let x = item.rcItem.left + max(1, (item.rcItem.right - item.rcItem.left) / 2)
        _ = MoveToEx(deviceContext, x, item.rcItem.top, nil)
        _ = LineTo(deviceContext, x, item.rcItem.bottom)
    }

    restore(object: oldPen, into: deviceContext)
    _ = DeleteObject(pen)
}

/// Converts radius to the diameter expected by `RoundRect`.
private func cornerDiameter(_ radius: Int32) -> Int32 {
    max(1, radius * 2)
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

/// Paints one segment of an integrated multi-part control.
private func paintSegmentBackground(
    _ rect: RECT,
    in deviceContext: HDC,
    role: SegmentedControlRole,
    palette: ButtonPalette,
    isPressed: Bool,
    isFocused: Bool
) {
    let fillBrush = CreateSolidBrush(palette.fill)
    let borderPen = CreatePen(PS_SOLID, isFocused ? 2 : 1, palette.border)
    let oldBrush = SelectObject(deviceContext, fillBrush)
    let oldPen = SelectObject(deviceContext, borderPen)
    let offset: Int32 = isPressed ? 1 : 0
    let rect = insetSegmentRect(rect, role: role, offset: offset)

    switch role {
    case .leading:
        _ = RoundRect(deviceContext, rect.left, rect.top, rect.right + 8, rect.bottom, 10, 10)
    case .center:
        _ = Rectangle(deviceContext, rect.left - 1, rect.top, rect.right + 1, rect.bottom)
    case .trailing:
        _ = RoundRect(deviceContext, rect.left - 8, rect.top, rect.right, rect.bottom, 10, 10)
    }

    restore(object: oldBrush, into: deviceContext)
    restore(object: oldPen, into: deviceContext)
    _ = DeleteObject(fillBrush)
    _ = DeleteObject(borderPen)
}

/// Adjusts segment drawing bounds while keeping borders visually connected.
private func insetSegmentRect(_ rect: RECT, role: SegmentedControlRole, offset: Int32) -> RECT {
    switch role {
    case .leading:
        return RECT(left: rect.left + offset, top: rect.top + offset, right: rect.right + 1 + offset, bottom: rect.bottom - 1 + offset)
    case .center:
        return RECT(left: rect.left + offset, top: rect.top + offset, right: rect.right + offset, bottom: rect.bottom - 1 + offset)
    case .trailing:
        return RECT(left: rect.left - 1 + offset, top: rect.top + offset, right: rect.right - 1 + offset, bottom: rect.bottom - 1 + offset)
    }
}

/// Paints an owner-drawn checkbox row.
private func drawToggle(_ item: DRAWITEMSTRUCT) {
    guard let deviceContext = item.hDC,
          let toggle = Win32ActionRegistry.toggles[UInt16(item.CtlID)] else {
        return
    }

    let isDisabled = (item.itemState & ODS_DISABLED) != 0
    let isHovered = isHot(item)
    paintControlSurface(item.rcItem, in: deviceContext)
    paintToggleBox(in: item.rcItem, deviceContext: deviceContext, isOn: toggle.isOn, isHovered: isHovered, isDisabled: isDisabled)
    paintToggleTitle(toggle.title, in: item.rcItem, deviceContext: deviceContext, isDisabled: isDisabled)
}

/// Paints the default surface behind an owner-drawn control.
///
/// Windows note:
/// `BS_OWNERDRAW` transfers the whole visual responsibility to us. If a
/// painter draws only the checkbox and text, the untouched row area can retain
/// the platform's default gray control fill instead of the surrounding panel.
private func paintControlSurface(_ rect: RECT, in deviceContext: HDC) {
    let brush = CreateSolidBrush(Win32PaintResources.controlSurfaceColor)
    let oldBrush = SelectObject(deviceContext, brush)
    let oldPen = SelectObject(deviceContext, GetStockObject(NULL_PEN))
    _ = Rectangle(deviceContext, rect.left, rect.top, rect.right, rect.bottom)
    restore(object: oldBrush, into: deviceContext)
    restore(object: oldPen, into: deviceContext)
    _ = DeleteObject(brush)
}

/// Paints the custom checkbox square.
private func paintToggleBox(in rect: RECT, deviceContext: HDC, isOn: Bool, isHovered: Bool, isDisabled: Bool) {
    let box = RECT(left: rect.left + 1, top: rect.top + 6, right: rect.left + 21, bottom: rect.top + 26)
    let fill = CreateSolidBrush(toggleFill(isOn: isOn, isHovered: isHovered, isDisabled: isDisabled))
    let border = CreatePen(PS_SOLID, isHovered && !isDisabled ? 2 : 1, toggleBorder(isOn: isOn, isHovered: isHovered, isDisabled: isDisabled))
    let oldBrush = SelectObject(deviceContext, fill)
    let oldPen = SelectObject(deviceContext, border)

    _ = RoundRect(deviceContext, box.left, box.top, box.right, box.bottom, 5, 5)
    restore(object: oldBrush, into: deviceContext)
    restore(object: oldPen, into: deviceContext)
    _ = DeleteObject(fill)
    _ = DeleteObject(border)

    if isOn {
        paintCheckmark(in: box, deviceContext: deviceContext, isDisabled: isDisabled)
    }
}

/// Paints a compact check mark.
private func paintCheckmark(in rect: RECT, deviceContext: HDC, isDisabled: Bool) {
    let pen = CreatePen(PS_SOLID, 2, isDisabled ? 0x008f8a86 : 0x00ffffff)
    let oldPen = SelectObject(deviceContext, pen)
    _ = MoveToEx(deviceContext, rect.left + 5, rect.top + 10, nil)
    _ = LineTo(deviceContext, rect.left + 9, rect.top + 14)
    _ = LineTo(deviceContext, rect.left + 15, rect.top + 6)
    restore(object: oldPen, into: deviceContext)
    _ = DeleteObject(pen)
}

/// Paints the text portion of a toggle row.
private func paintToggleTitle(_ title: String, in rect: RECT, deviceContext: HDC, isDisabled: Bool) {
    _ = SetBkMode(deviceContext, TRANSPARENT)
    _ = SetTextColor(deviceContext, isDisabled ? 0x008f8a86 : 0x00271811)

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
    let isDisabled = (item.itemState & ODS_DISABLED) != 0
    let isHovered = isHot(item)
    paintPickerOptionBackground(item.rcItem, deviceContext: deviceContext, isSelected: isSelected, isHovered: isHovered, isDisabled: isDisabled)
    paintPickerOptionTitle(option.picker.options[option.index], in: item.rcItem, deviceContext: deviceContext, isSelected: isSelected, isDisabled: isDisabled)
}

/// Paints a pill-style picker option background.
private func paintPickerOptionBackground(_ rect: RECT, deviceContext: HDC, isSelected: Bool, isHovered: Bool, isDisabled: Bool) {
    let fill = CreateSolidBrush(pickerFill(isSelected: isSelected, isHovered: isHovered, isDisabled: isDisabled))
    let border = CreatePen(PS_SOLID, isHovered && !isDisabled ? 2 : 1, pickerBorder(isSelected: isSelected, isHovered: isHovered, isDisabled: isDisabled))
    let oldBrush = SelectObject(deviceContext, fill)
    let oldPen = SelectObject(deviceContext, border)

    _ = RoundRect(deviceContext, rect.left, rect.top + 1, rect.right - 1, rect.bottom - 1, 12, 12)
    restore(object: oldBrush, into: deviceContext)
    restore(object: oldPen, into: deviceContext)
    _ = DeleteObject(fill)
    _ = DeleteObject(border)
}

/// Paints picker option text.
private func paintPickerOptionTitle(_ title: String, in rect: RECT, deviceContext: HDC, isSelected: Bool, isDisabled: Bool) {
    _ = SetBkMode(deviceContext, TRANSPARENT)
    _ = SetTextColor(deviceContext, pickerText(isSelected: isSelected, isDisabled: isDisabled))

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

/// Paints centered text for non-button segments.
private func paintSegmentText(_ title: String, in rect: RECT, deviceContext: HDC, color: DWORD) {
    _ = SetBkMode(deviceContext, TRANSPARENT)
    _ = SetTextColor(deviceContext, color)

    var textRect = rect
    textRect.left += 8
    textRect.right -= 8

    withWideString(title) { title in
        _ = DrawTextW(deviceContext, title, -1, &textRect, DT_CENTER | DT_VCENTER | DT_SINGLELINE)
    }
}

/// Returns owner-draw colors for the current button state.
private func buttonPalette(for style: WinButtonStyle, isPressed: Bool, isHovered: Bool, isDisabled: Bool) -> ButtonPalette {
    if isDisabled {
        return ButtonPalette(fill: 0x00efebe8, border: 0x00d9d2cd, text: 0x008f8a86)
    }

    switch style {
    case .primary:
        return ButtonPalette(
            fill: primaryButtonFill(isPressed: isPressed, isHovered: isHovered),
            border: isPressed ? 0x00b84818 : 0x00d95b20,
            text: 0x00ffffff
        )
    case .secondary:
        return ButtonPalette(
            fill: secondaryButtonFill(isPressed: isPressed, isHovered: isHovered),
            border: isHovered ? 0x00c8bdb7 : 0x00ddd4cf,
            text: 0x00271811
        )
    }
}

/// Returns the primary button fill color for interaction state.
private func primaryButtonFill(isPressed: Bool, isHovered: Bool) -> DWORD {
    if isPressed {
        return 0x00c8521d
    }
    if isHovered {
        return 0x00f06f31
    }

    return 0x00eb6325
}

/// Returns the secondary button fill color for interaction state.
private func secondaryButtonFill(isPressed: Bool, isHovered: Bool) -> DWORD {
    if isPressed {
        return 0x00f0ecea
    }
    if isHovered {
        return 0x00faf6f3
    }

    return 0x00ffffff
}

/// Returns the custom checkbox fill color.
private func toggleFill(isOn: Bool, isHovered: Bool, isDisabled: Bool) -> DWORD {
    if isDisabled {
        return isOn ? 0x00d9d2cd : 0x00f5f1ee
    }
    if isHovered && !isOn {
        return 0x00faf6f3
    }

    return isOn ? 0x00eb6325 : 0x00ffffff
}

/// Returns the custom checkbox border color.
private func toggleBorder(isOn: Bool, isHovered: Bool, isDisabled: Bool) -> DWORD {
    if isDisabled {
        return 0x00c8c0ba
    }
    if isHovered {
        return isOn ? 0x00b84818 : 0x00eb6325
    }

    return isOn ? 0x00d95b20 : 0x00cfc7c2
}

/// Returns the segmented picker fill color.
private func pickerFill(isSelected: Bool, isHovered: Bool, isDisabled: Bool) -> DWORD {
    if isDisabled {
        return isSelected ? 0x00e8e1dd : 0x00f5f1ee
    }
    if isHovered && !isSelected {
        return 0x00faf6f3
    }

    return isSelected ? 0x00f7e6dc : 0x00ffffff
}

/// Returns the segmented picker border color.
private func pickerBorder(isSelected: Bool, isHovered: Bool, isDisabled: Bool) -> DWORD {
    if isDisabled {
        return 0x00d9d2cd
    }
    if isHovered {
        return 0x00eb6325
    }

    return isSelected ? 0x00eb6325 : 0x00ddd4cf
}

/// Returns the segmented picker text color.
private func pickerText(isSelected: Bool, isDisabled: Bool) -> DWORD {
    if isDisabled {
        return 0x008f8a86
    }

    return isSelected ? 0x00b84818 : 0x00271811
}

/// Returns whether an owner-drawn item should paint hover state.
private func isHot(_ item: DRAWITEMSTRUCT) -> Bool {
    (item.itemState & ODS_HOTLIGHT) != 0 || Win32ActionRegistry.hoveredControlIDs.contains(item.CtlID)
}

/// Owner-draw color palette.
private struct ButtonPalette {
    var fill: DWORD
    var border: DWORD
    var text: DWORD
}
#endif
