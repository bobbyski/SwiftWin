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

/// Shared paint resources for the current Win32 prototype.
enum Win32PaintResources {
    nonisolated(unsafe) static var backgroundBrush: HBRUSH?
}
#endif
