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
    nonisolated(unsafe) static var dynamicTexts: [UInt16: DynamicTextRenderState] = [:]
    nonisolated(unsafe) static var textFields: [UInt16: WinTextField] = [:]
    nonisolated(unsafe) static var toggles: [UInt16: WinToggle] = [:]
    nonisolated(unsafe) static var toggleControls: [UInt16: HWND] = [:]
    nonisolated(unsafe) static var pickerOptions: [UInt16: PickerOptionState] = [:]
    nonisolated(unsafe) static var pickerOptionControls: [UInt16: HWND] = [:]
    nonisolated(unsafe) static var slidersByHandle: [UInt: SliderRenderState] = [:]
    nonisolated(unsafe) static var backgrounds: [UInt32: BackgroundRenderState] = [:]
    nonisolated(unsafe) static var borders: [UInt32: BorderRenderState] = [:]
    nonisolated(unsafe) static var staticTextColorsByHandle: [UInt: DWORD] = [:]
    nonisolated(unsafe) static var staticBackgroundBrushesByHandle: [UInt: HBRUSH] = [:]
    nonisolated(unsafe) static var controlFramesByHandle: [UInt: ControlFrame] = [:]
    nonisolated(unsafe) static var originalControlProceduresByHandle: [UInt: WNDPROC] = [:]
    nonisolated(unsafe) static var hoveredControlIDs: Set<UInt32> = []
    nonisolated(unsafe) static var scrollState = WindowScrollState()

    /// Clears per-window state before a new demo window is rendered.
    static func reset() {
        actions.removeAll()
        buttons.removeAll()
        dynamicTexts.removeAll()
        textFields.removeAll()
        toggles.removeAll()
        toggleControls.removeAll()
        pickerOptions.removeAll()
        pickerOptionControls.removeAll()
        slidersByHandle.removeAll()
        backgrounds.removeAll()
        borders.removeAll()
        staticTextColorsByHandle.removeAll()
        staticBackgroundBrushesByHandle.removeAll()
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
        for state in Win32ActionRegistry.dynamicTexts.values {
            updateDynamicText(state)
        }
        #endif
    }
}

/// Updates one dynamic text HWND from its provider.
private func updateDynamicText(_ state: DynamicTextRenderState) {
    withWideString(state.text.value) { value in
        _ = SetWindowTextW(state.control, value)
    }
}

/// Owner-draw metadata for a button.
struct ButtonRenderState {
    var title: String
    var style: WinButtonStyle
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
}
#endif
