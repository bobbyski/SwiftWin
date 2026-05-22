/// Traditional imperative application runtime for SwiftWin.
///
/// `WinApplication` is the Phase II entry point. It owns the native runtime
/// path directly and is intentionally not declarative. The SwiftUI-compatible
/// `SwiftWinUI` layer currently wraps this API on Windows.
public final class WinApplication: WinApplicationRunning {
    /// Creates an application runtime.
    public init() {}

    /// Runs a window until its native message loop exits.
    ///
    /// On Windows this creates and shows a Win32 window. On non-Windows
    /// platforms it prints the imperative tree for diagnostics.
    public func run(_ window: WinWindow) {
        #if os(Windows)
        Win32ApplicationRunner().run(window)
        #else
        ConsoleLegacyRenderer().render(window)
        #endif
    }
}

/// Top-level traditional window description.
///
/// This type is deliberately mutable so traditional code can construct a
/// window, attach content, then run it. Future versions should add lifecycle
/// events, resize callbacks, and close handling.
public final class WinWindow {
    /// Native window title.
    public var title: String
    /// Initial window width.
    public var width: Int
    /// Initial window height.
    public var height: Int
    /// Root content element displayed in the window.
    public var content: WinElement?

    /// Creates a window descriptor.
    public init(title: String, width: Int = 960, height: Int = 640, content: WinElement? = nil) {
        self.title = title
        self.width = width
        self.height = height
        self.content = content
    }
}
