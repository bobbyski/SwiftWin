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
    nonisolated(unsafe) static var textFields: [UInt16: WinTextField] = [:]
}

/// Owner-draw metadata for a button.
struct ButtonRenderState {
    var title: String
    var style: WinButtonStyle
}

/// Shared paint resources for the current Win32 prototype.
enum Win32PaintResources {
    nonisolated(unsafe) static var backgroundBrush: HBRUSH?
}
#endif
