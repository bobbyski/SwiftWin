/// Simple color picker control in the traditional API.
///
/// This first implementation cycles through a small built-in palette when
/// clicked. It proves color state, callbacks, binding refresh, and owner-drawn
/// swatch rendering before the Windows common color dialog is introduced.
public final class WinColorPicker: WinColorControl, WinRefreshableControl {
    /// Label describing the color.
    public var title: String
    /// Current RGB color.
    public var color: WinForegroundStyle
    /// Closure invoked after native interaction changes the color.
    public var onChange: ((WinForegroundStyle) -> Void)?
    /// Optional source of truth used when external state invalidates the view.
    public var colorProvider: (() -> WinForegroundStyle)?

    /// Built-in demo palette used by the first control implementation.
    public static let defaultPalette: [WinForegroundStyle] = [
        WinForegroundStyle(red: 37, green: 99, blue: 235),
        WinForegroundStyle(red: 22, green: 163, blue: 74),
        WinForegroundStyle(red: 220, green: 38, blue: 38),
        WinForegroundStyle(red: 147, green: 51, blue: 234),
        WinForegroundStyle(red: 234, green: 88, blue: 12),
        WinForegroundStyle(red: 17, green: 24, blue: 39),
    ]

    /// Creates a color picker.
    public init(
        _ title: String,
        color: WinForegroundStyle = .accent,
        onChange: ((WinForegroundStyle) -> Void)? = nil,
        colorProvider: (() -> WinForegroundStyle)? = nil
    ) {
        self.title = title
        self.color = color
        self.onChange = onChange
        self.colorProvider = colorProvider
    }

    /// Mirrors the current Swift value into the active native control.
    public func refresh() {
        WinControlInvalidation.refresh(self)
    }
}
