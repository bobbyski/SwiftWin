#if os(Windows)
/// Global action/drawing registries keyed by Win32 control IDs.
///
/// Implementation note:
/// This prototype uses process-global mutable state because the C window
/// procedure does not receive the Swift runner instance directly. A future
/// version should attach per-window state with `GWLP_USERDATA` or a similar
/// handle-to-object mapping.
enum Win32ActionRegistry {
    nonisolated(unsafe) static var actions: [UInt16: () -> Void] = [:]
    nonisolated(unsafe) static var buttons: [UInt32: ButtonRenderState] = [:]
    nonisolated(unsafe) static var links: [UInt32: LinkRenderState] = [:]
    nonisolated(unsafe) static var stepperValues: [UInt32: StepperValueRenderState] = [:]
    nonisolated(unsafe) static var stepperLabels: [UInt: StepperLabelRenderState] = [:]
    nonisolated(unsafe) static var dynamicTexts: [UInt16: DynamicTextRenderState] = [:]
    nonisolated(unsafe) static var progressViews: [UInt: ProgressRenderState] = [:]
    nonisolated(unsafe) static var textFields: [UInt16: WinTextField] = [:]
    nonisolated(unsafe) static var secureFields: [UInt16: WinSecureField] = [:]
    nonisolated(unsafe) static var textEditors: [UInt16: WinTextEditor] = [:]
    nonisolated(unsafe) static var toggles: [UInt16: WinToggle] = [:]
    nonisolated(unsafe) static var toggleControls: [UInt16: HWND] = [:]
    nonisolated(unsafe) static var pickerOptions: [UInt16: PickerOptionState] = [:]
    nonisolated(unsafe) static var pickerOptionControls: [UInt16: HWND] = [:]
    nonisolated(unsafe) static var colorPickers: [UInt16: WinColorPicker] = [:]
    nonisolated(unsafe) static var colorPickerControls: [UInt16: HWND] = [:]
    nonisolated(unsafe) static var datePickers: [UInt16: WinDatePicker] = [:]
    nonisolated(unsafe) static var datePickerControls: [UInt16: HWND] = [:]
    nonisolated(unsafe) static var slidersByHandle: [UInt: SliderRenderState] = [:]
    nonisolated(unsafe) static var backgrounds: [UInt32: BackgroundRenderState] = [:]
    nonisolated(unsafe) static var borders: [UInt32: BorderRenderState] = [:]
    nonisolated(unsafe) static var separators: [UInt32: SeparatorRenderState] = [:]
    nonisolated(unsafe) static var staticTextColorsByHandle: [UInt: DWORD] = [:]
    nonisolated(unsafe) static var staticBackgroundBrushesByHandle: [UInt: HBRUSH] = [:]
    nonisolated(unsafe) static var mutableTextSurfaceHandles: Set<UInt> = []
    nonisolated(unsafe) static var controlFramesByHandle: [UInt: ControlFrame] = [:]
    nonisolated(unsafe) static var originalControlProceduresByHandle: [UInt: WNDPROC] = [:]
    nonisolated(unsafe) static var hoveredControlIDs: Set<UInt32> = []
    nonisolated(unsafe) static var focusedControlIDs: Set<UInt32> = []
    nonisolated(unsafe) static var scrollState = WindowScrollState()

    /// Clears per-window state before a new demo window is rendered.
    static func reset() {
        actions.removeAll()
        buttons.removeAll()
        links.removeAll()
        stepperValues.removeAll()
        stepperLabels.removeAll()
        dynamicTexts.removeAll()
        progressViews.removeAll()
        textFields.removeAll()
        secureFields.removeAll()
        textEditors.removeAll()
        toggles.removeAll()
        toggleControls.removeAll()
        pickerOptions.removeAll()
        pickerOptionControls.removeAll()
        colorPickers.removeAll()
        colorPickerControls.removeAll()
        datePickers.removeAll()
        datePickerControls.removeAll()
        slidersByHandle.removeAll()
        backgrounds.removeAll()
        borders.removeAll()
        separators.removeAll()
        staticTextColorsByHandle.removeAll()
        staticBackgroundBrushesByHandle.removeAll()
        mutableTextSurfaceHandles.removeAll()
        controlFramesByHandle.removeAll()
        originalControlProceduresByHandle.removeAll()
        hoveredControlIDs.removeAll()
        focusedControlIDs.removeAll()
        scrollState = WindowScrollState()
    }
}

/// Native control associated with dynamic text.
struct DynamicTextRenderState {
    var text: WinDynamicText
    var control: HWND
}

/// Invalidates dynamic text controls after declarative state changes.
public enum WinDynamicTextInvalidation {
    /// Refreshes all registered dynamic text labels.
    public static func invalidateAll() {
        #if os(Windows)
        refreshProviderBackedControls()
        for state in Win32ActionRegistry.dynamicTexts.values {
            updateDynamicText(state)
        }
        for state in Win32ActionRegistry.progressViews.values {
            updateProgressView(state)
        }
        #endif
    }
}

/// Public refresh entry points for imperative controls.
///
/// The methods live beside the Win32 registry today because the active native
/// peers are stored there. A future per-window runtime object should own these
/// lookups instead of process-global state.
public enum WinControlInvalidation {
    /// Refreshes several controls and invalidates dependent UI once.
    public static func refresh(_ controls: [WinRefreshableControl]) {
        #if os(Windows)
        for control in controls {
            refreshNativePeer(control)
        }
        WinDynamicTextInvalidation.invalidateAll()
        #endif
    }

    /// Refreshes a text field from its current Swift value.
    public static func refresh(_ textField: WinTextField) {
        #if os(Windows)
        refreshNativePeer(textField)
        WinDynamicTextInvalidation.invalidateAll()
        #endif
    }

    /// Refreshes a secure field from its current Swift value.
    public static func refresh(_ secureField: WinSecureField) {
        #if os(Windows)
        refreshNativePeer(secureField)
        WinDynamicTextInvalidation.invalidateAll()
        #endif
    }

    /// Refreshes a text editor from its current Swift value.
    public static func refresh(_ textEditor: WinTextEditor) {
        #if os(Windows)
        refreshNativePeer(textEditor)
        WinDynamicTextInvalidation.invalidateAll()
        #endif
    }

    /// Refreshes a toggle from its current Swift value.
    public static func refresh(_ toggle: WinToggle) {
        #if os(Windows)
        refreshNativePeer(toggle)
        WinDynamicTextInvalidation.invalidateAll()
        #endif
    }

    /// Refreshes a picker from its current Swift selection.
    public static func refresh(_ picker: WinPicker) {
        #if os(Windows)
        refreshNativePeer(picker)
        WinDynamicTextInvalidation.invalidateAll()
        #endif
    }

    /// Refreshes a color picker from its current Swift value.
    public static func refresh(_ colorPicker: WinColorPicker) {
        #if os(Windows)
        refreshNativePeer(colorPicker)
        WinDynamicTextInvalidation.invalidateAll()
        #endif
    }

    /// Refreshes a date picker from its current Swift value.
    public static func refresh(_ datePicker: WinDatePicker) {
        #if os(Windows)
        refreshNativePeer(datePicker)
        WinDynamicTextInvalidation.invalidateAll()
        #endif
    }

    /// Refreshes a slider from its current Swift value.
    public static func refresh(_ slider: WinSlider) {
        #if os(Windows)
        refreshNativePeer(slider)
        WinDynamicTextInvalidation.invalidateAll()
        #endif
    }

    /// Refreshes a stepper from its current Swift value.
    public static func refresh(_ stepper: WinStepper) {
        #if os(Windows)
        refreshNativePeer(stepper)
        WinDynamicTextInvalidation.invalidateAll()
        #endif
    }
}

/// Mirrors one refreshable control into its active native peer.
private func refreshNativePeer(_ control: WinRefreshableControl) {
    switch control {
    case let textField as WinTextField:
        refreshTextField(textField)
    case let secureField as WinSecureField:
        refreshSecureField(secureField)
    case let textEditor as WinTextEditor:
        refreshTextEditor(textEditor)
    case let toggle as WinToggle:
        refreshToggle(toggle)
    case let picker as WinPicker:
        refreshPicker(picker)
    case let colorPicker as WinColorPicker:
        refreshColorPicker(colorPicker)
    case let datePicker as WinDatePicker:
        refreshDatePicker(datePicker)
    case let slider as WinSlider:
        refreshSlider(slider)
    case let stepper as WinStepper:
        refreshStepper(stepper)
    default:
        break
    }
}

/// Refreshes native controls whose values can be read from external state.
///
/// Implementation decision:
/// This is a narrow reconciliation pass, not a full SwiftUI diff. It lets
/// `@State` and `Binding` update existing HWND controls while the runtime is
/// still direct-placement and identity-light.
private func refreshProviderBackedControls() {
    refreshTextFields()
    refreshSecureFields()
    refreshTextEditors()
    refreshToggles()
    refreshPickers()
    refreshColorPickers()
    refreshDatePickers()
    refreshSliders()
    refreshSteppers()
}

/// Mirrors provider-backed date pickers into native common controls.
private func refreshDatePickers() {
    for (controlID, datePicker) in Win32ActionRegistry.datePickers {
        guard let value = datePicker.dateProvider?(),
              value != datePicker.date,
              let control = Win32ActionRegistry.datePickerControls[controlID] else {
            continue
        }

        datePicker.date = value
        setNativeDate(control, date: value)
    }
}

/// Mirrors one date picker object into its active native control.
private func refreshDatePicker(_ datePicker: WinDatePicker) {
    for (controlID, candidate) in Win32ActionRegistry.datePickers where candidate === datePicker {
        guard let control = Win32ActionRegistry.datePickerControls[controlID] else {
            continue
        }

        setNativeDate(control, date: datePicker.date)
    }
}

/// Mirrors provider-backed color pickers into owner-drawn controls.
private func refreshColorPickers() {
    for (controlID, colorPicker) in Win32ActionRegistry.colorPickers {
        guard let value = colorPicker.colorProvider?(),
              value != colorPicker.color,
              let control = Win32ActionRegistry.colorPickerControls[controlID] else {
            continue
        }

        colorPicker.color = value
        _ = InvalidateRect(control, nil, 1)
    }
}

/// Mirrors one color picker object into its active owner-drawn control.
private func refreshColorPicker(_ colorPicker: WinColorPicker) {
    for (controlID, candidate) in Win32ActionRegistry.colorPickers where candidate === colorPicker {
        guard let control = Win32ActionRegistry.colorPickerControls[controlID] else {
            continue
        }

        _ = InvalidateRect(control, nil, 1)
    }
}

/// Mirrors provider-backed secure fields into their native edit controls.
private func refreshSecureFields() {
    for (controlID, secureField) in Win32ActionRegistry.secureFields {
        guard let value = secureField.textProvider?(),
              value != secureField.value,
              let control = control(withID: controlID) else {
            continue
        }

        secureField.value = value
        withWideString(value) { text in
            _ = SetWindowTextW(control, text)
        }
    }
}

/// Mirrors one secure field object into its active native edit control.
private func refreshSecureField(_ secureField: WinSecureField) {
    guard let control = secureFieldControl(for: secureField) else {
        return
    }

    withWideString(secureField.value) { text in
        _ = SetWindowTextW(control, text)
    }
}

/// Mirrors provider-backed text editors into their native edit controls.
private func refreshTextEditors() {
    for (controlID, textEditor) in Win32ActionRegistry.textEditors {
        guard let value = textEditor.textProvider?(),
              value != textEditor.value,
              let control = control(withID: controlID) else {
            continue
        }

        textEditor.value = value
        withWideString(value) { text in
            _ = SetWindowTextW(control, text)
        }
    }
}

/// Mirrors one text editor object into its active native edit control.
private func refreshTextEditor(_ textEditor: WinTextEditor) {
    guard let control = textEditorControl(for: textEditor) else {
        return
    }

    withWideString(textEditor.value) { text in
        _ = SetWindowTextW(control, text)
    }
}

/// Mirrors provider-backed text fields into their native edit controls.
private func refreshTextFields() {
    for (controlID, textField) in Win32ActionRegistry.textFields {
        guard let value = textField.textProvider?(),
              value != textField.value,
              let control = Win32ActionRegistry.controlFramesByHandle.values.first(where: { GetDlgCtrlID($0.control) == Int32(controlID) })?.control else {
            continue
        }

        textField.value = value
        withWideString(value) { text in
            _ = SetWindowTextW(control, text)
        }
    }
}

/// Mirrors one text field object into its active native edit control.
private func refreshTextField(_ textField: WinTextField) {
    guard let control = textFieldControl(for: textField) else {
        return
    }

    withWideString(textField.value) { text in
        _ = SetWindowTextW(control, text)
    }
}

/// Mirrors provider-backed toggles into owner-drawn checkbox controls.
private func refreshToggles() {
    for (controlID, toggle) in Win32ActionRegistry.toggles {
        guard let value = toggle.valueProvider?(),
              value != toggle.isOn,
              let control = Win32ActionRegistry.toggleControls[controlID] else {
            continue
        }

        toggle.isOn = value
        _ = InvalidateRect(control, nil, 1)
    }
}

/// Mirrors one toggle object into its active owner-drawn control.
private func refreshToggle(_ toggle: WinToggle) {
    for (controlID, candidate) in Win32ActionRegistry.toggles where candidate === toggle {
        guard let control = Win32ActionRegistry.toggleControls[controlID] else {
            continue
        }

        _ = InvalidateRect(control, nil, 1)
    }
}

/// Mirrors provider-backed picker selections into owner-drawn options.
private func refreshPickers() {
    for option in Win32ActionRegistry.pickerOptions.values {
        guard let providerValue = option.picker.selectionProvider?() else {
            continue
        }

        let clamped = min(max(providerValue, 0), max(0, option.picker.options.count - 1))
        if clamped != option.picker.selectedIndex {
            option.picker.selectedIndex = clamped
        }
    }

    for control in Win32ActionRegistry.pickerOptionControls.values {
        _ = InvalidateRect(control, nil, 1)
    }
}

/// Mirrors one picker object into its active owner-drawn options.
private func refreshPicker(_ picker: WinPicker) {
    for (controlID, option) in Win32ActionRegistry.pickerOptions where option.picker === picker {
        guard let control = Win32ActionRegistry.pickerOptionControls[controlID] else {
            continue
        }

        _ = InvalidateRect(control, nil, 1)
    }
}

/// Mirrors provider-backed sliders into their trackbars and value labels.
private func refreshSliders() {
    for (handle, state) in Win32ActionRegistry.slidersByHandle {
        guard let providerValue = state.slider.valueProvider?(),
              let control = HWND(bitPattern: handle) else {
            continue
        }

        setSlider(state, value: providerValue, control: control, notify: false)
    }
}

/// Mirrors one slider object into its active trackbar and label.
private func refreshSlider(_ slider: WinSlider) {
    for (handle, state) in Win32ActionRegistry.slidersByHandle where state.slider === slider {
        guard let control = HWND(bitPattern: handle) else {
            continue
        }

        setSlider(state, value: slider.value, control: control, notify: false, force: true)
    }
}

/// Mirrors provider-backed steppers into their labels and value segments.
private func refreshSteppers() {
    for state in Win32ActionRegistry.stepperLabels.values {
        guard let providerValue = state.stepper.valueProvider?() else {
            continue
        }

        setStepperLabel(state, value: providerValue)
    }

    for controlID in Win32ActionRegistry.stepperValues.keys {
        guard let frame = Win32ActionRegistry.controlFramesByHandle.values.first(where: { GetDlgCtrlID($0.control) == Int32(controlID) }) else {
            continue
        }

        _ = InvalidateRect(frame.control, nil, 1)
    }
}

/// Mirrors one stepper object into its active labels and value segments.
private func refreshStepper(_ stepper: WinStepper) {
    for state in Win32ActionRegistry.stepperLabels.values where state.stepper === stepper {
        updateStepperLabel(state)
    }
    invalidateStepperValueSegments(for: stepper)
}

/// Returns the native edit control registered for one text field.
private func textFieldControl(for textField: WinTextField) -> HWND? {
    guard let entry = Win32ActionRegistry.textFields.first(where: { $0.value === textField }) else {
        return nil
    }

    return control(withID: entry.key)
}

/// Returns the native edit control registered for one secure field.
private func secureFieldControl(for secureField: WinSecureField) -> HWND? {
    guard let entry = Win32ActionRegistry.secureFields.first(where: { $0.value === secureField }) else {
        return nil
    }

    return control(withID: entry.key)
}

/// Returns the native edit control registered for one text editor.
private func textEditorControl(for textEditor: WinTextEditor) -> HWND? {
    guard let entry = Win32ActionRegistry.textEditors.first(where: { $0.value === textEditor }) else {
        return nil
    }

    return control(withID: entry.key)
}

/// Finds a native child control by Win32 dialog/control ID.
private func control(withID controlID: UInt16) -> HWND? {
    Win32ActionRegistry.controlFramesByHandle.values.first {
        GetDlgCtrlID($0.control) == Int32(controlID)
    }?.control
}

/// Redraws owner-drawn value segments for one stepper.
private func invalidateStepperValueSegments(for stepper: WinStepper) {
    for (controlID, state) in Win32ActionRegistry.stepperValues where state.stepper === stepper {
        guard let frame = Win32ActionRegistry.controlFramesByHandle.values.first(where: { GetDlgCtrlID($0.control) == Int32(controlID) }) else {
            continue
        }

        _ = InvalidateRect(frame.control, nil, 1)
    }
}

/// Updates one dynamic text HWND from its provider.
private func updateDynamicText(_ state: DynamicTextRenderState) {
    withWideString(state.text.value) { value in
        _ = SetWindowTextW(state.control, value)
    }
}

/// Native control associated with a progress view.
struct ProgressRenderState {
    var progressView: WinProgressView
    var control: HWND
}

/// Updates one progress bar HWND from its provider.
private func updateProgressView(_ state: ProgressRenderState) {
    _ = SendMessageW(state.control, PBM_SETPOS, WPARAM(progressPosition(for: state.progressView)), 0)
}

/// Stores a slider value and mirrors it back to native controls.
func setSlider(_ state: SliderRenderState, value: Int, control: HWND, notify: Bool, force: Bool = false) {
    let slider = state.slider
    let clamped = min(max(value, slider.minimum), slider.maximum)
    guard force || clamped != slider.value else {
        return
    }

    slider.value = clamped
    updateSliderLabel(state.label, slider: slider)
    _ = SendMessageW(control, TBM_SETPOS, 1, LPARAM(clamped))
    if notify {
        slider.onChange?(clamped)
    }
}

/// Updates the static text label owned by a slider.
private func updateSliderLabel(_ label: HWND, slider: WinSlider) {
    withWideString("\(slider.title): \(slider.value)") { text in
        _ = SetWindowTextW(label, text)
    }
}

/// Stores a stepper value and mirrors it back to one native label.
func setStepperLabel(_ state: StepperLabelRenderState, value: Int) {
    let stepper = state.stepper
    let clamped = min(max(value, stepper.minimum), stepper.maximum)
    guard clamped != stepper.value else {
        return
    }

    stepper.value = clamped
    updateStepperLabel(state)
}

/// Updates the static text label owned by a stepper.
func updateStepperLabel(_ state: StepperLabelRenderState) {
    let value = state.displaysValueOnly ? "\(state.stepper.value)" : "\(state.stepper.title): \(state.stepper.value)"
    withWideString(value) { text in
        _ = SetWindowTextW(state.label, text)
    }
    _ = InvalidateRect(state.label, nil, 1)
}

/// Converts a progress view value into a normalized progress-bar position.
func progressPosition(for progressView: WinProgressView) -> Int {
    let ratio = min(max(progressView.value / progressView.total, 0), 1)
    return Int((ratio * 1000).rounded())
}

/// Owner-draw metadata for a button.
struct ButtonRenderState {
    var title: String
    var style: WinButtonStyle
    var segmentRole: SegmentedControlRole? = nil
}

/// Owner-draw metadata for an external link.
struct LinkRenderState {
    var title: String
    var destination: String
}

/// Owner-draw metadata for an integrated stepper value segment.
struct StepperValueRenderState {
    var stepper: WinStepper
}

/// Native label associated with a stepper value.
struct StepperLabelRenderState {
    var stepper: WinStepper
    var label: HWND
    var displaysValueOnly: Bool
}

/// Position of a segment inside a cohesive multi-part control.
enum SegmentedControlRole {
    case leading
    case center
    case trailing
}

/// Maps one radio button control ID to a picker option.
struct PickerOptionState {
    var picker: WinPicker
    var index: Int
}

/// Native controls associated with a slider.
struct SliderRenderState {
    var slider: WinSlider
    var label: HWND
}

/// Owner-draw metadata for a background panel.
struct BackgroundRenderState {
    var color: WinForegroundStyle
    var cornerRadius: Int32
}

/// Owner-draw metadata for a border panel.
struct BorderRenderState {
    var color: WinForegroundStyle
    var width: Int32
    var cornerRadius: Int32
}

/// Owner-draw metadata for a separator line.
struct SeparatorRenderState {
    var axis: WinSeparatorAxis
    var color: WinForegroundStyle
    var thickness: Int32
}

/// Original position and size for a child HWND before scroll offset is applied.
struct ControlFrame {
    var control: HWND
    var x: Int32
    var y: Int32
    var width: Int32
    var height: Int32
}

/// Current vertical scroll state for the active prototype window.
struct WindowScrollState {
    var contentHeight: Int32 = 0
    var offset: Int32 = 0
}

/// Shared paint resources for the current Win32 prototype.
enum Win32PaintResources {
    nonisolated(unsafe) static var backgroundBrush: HBRUSH?
    nonisolated(unsafe) static var controlSurfaceBrush: HBRUSH?
    nonisolated(unsafe) static var focusedEditBrush: HBRUSH?
    nonisolated(unsafe) static var controlSurfaceColor: DWORD = 0x00fff6ef
    nonisolated(unsafe) static var focusedEditColor: DWORD = 0x00d3f8ff
}

/// Converts a framework date to the Win32 `SYSTEMTIME` shape.
func systemTime(from date: WinDate) -> SYSTEMTIME {
    SYSTEMTIME(
        wYear: UInt16(clamping: date.year),
        wMonth: UInt16(clamping: date.month),
        wDayOfWeek: 0,
        wDay: UInt16(clamping: date.day),
        wHour: 0,
        wMinute: 0,
        wSecond: 0,
        wMilliseconds: 0
    )
}

/// Converts a Win32 `SYSTEMTIME` date into the framework value type.
func winDate(from systemTime: SYSTEMTIME) -> WinDate {
    WinDate(
        year: Int(systemTime.wYear),
        month: Int(systemTime.wMonth),
        day: Int(systemTime.wDay)
    )
}

/// Mirrors a Swift date into a Win32 date picker HWND.
func setNativeDate(_ control: HWND, date: WinDate) {
    var systemTime = systemTime(from: date)
    withUnsafePointer(to: &systemTime) { pointer in
        _ = SendMessageW(control, DTM_SETSYSTEMTIME, GDT_VALID, LPARAM(Int(bitPattern: pointer)))
    }
}

#endif
