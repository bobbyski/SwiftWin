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
    nonisolated(unsafe) static var stepperValues: [UInt32: StepperValueRenderState] = [:]
    nonisolated(unsafe) static var stepperLabels: [UInt: StepperLabelRenderState] = [:]
    nonisolated(unsafe) static var dynamicTexts: [UInt16: DynamicTextRenderState] = [:]
    nonisolated(unsafe) static var progressViews: [UInt: ProgressRenderState] = [:]
    nonisolated(unsafe) static var textFields: [UInt16: WinTextField] = [:]
    nonisolated(unsafe) static var toggles: [UInt16: WinToggle] = [:]
    nonisolated(unsafe) static var toggleControls: [UInt16: HWND] = [:]
    nonisolated(unsafe) static var pickerOptions: [UInt16: PickerOptionState] = [:]
    nonisolated(unsafe) static var pickerOptionControls: [UInt16: HWND] = [:]
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
    nonisolated(unsafe) static var scrollState = WindowScrollState()

    /// Clears per-window state before a new demo window is rendered.
    static func reset() {
        actions.removeAll()
        buttons.removeAll()
        stepperValues.removeAll()
        stepperLabels.removeAll()
        dynamicTexts.removeAll()
        progressViews.removeAll()
        textFields.removeAll()
        toggles.removeAll()
        toggleControls.removeAll()
        pickerOptions.removeAll()
        pickerOptionControls.removeAll()
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

/// Refreshes native controls whose values can be read from external state.
///
/// Implementation decision:
/// This is a narrow reconciliation pass, not a full SwiftUI diff. It lets
/// `@State` and `Binding` update existing HWND controls while the runtime is
/// still direct-placement and identity-light.
private func refreshProviderBackedControls() {
    refreshTextFields()
    refreshToggles()
    refreshPickers()
    refreshSliders()
    refreshSteppers()
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
func setSlider(_ state: SliderRenderState, value: Int, control: HWND, notify: Bool) {
    let slider = state.slider
    let clamped = min(max(value, slider.minimum), slider.maximum)
    guard clamped != slider.value else {
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
    nonisolated(unsafe) static var controlSurfaceColor: DWORD = 0x00fff6ef
}
#endif
