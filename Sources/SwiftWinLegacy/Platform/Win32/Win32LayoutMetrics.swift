#if os(Windows)
/// Shared layout metrics for the Win32 backend.
///
/// Design intent:
/// The SDK should make Swift-written Windows apps feel familiar to Apple
/// platform developers while still respecting native Windows mechanics. Win32
/// controls clip to their assigned rectangles, so default metrics must include
/// enough polish padding for real GDI fonts instead of requiring every app to
/// add one-off frames.
enum Win32LayoutMetrics {
    /// Default root content inset from a top-level window.
    static let rootInset: Int32 = 36

    /// Default vertical origin for window content.
    static let rootTop: Int32 = 34

    /// Default stack spacing used when the app does not provide one.
    static let stackSpacing: Int32 = 12

    /// Returns the default single-line `STATIC` width for a text value.
    ///
    /// Implementation note:
    /// This is a compatibility bridge until the layout engine grows a real
    /// measure pass using `GetTextExtentPoint32W` or equivalent font metrics.
    static func textWidth(for value: String, style: WinTextStyle) -> Int32 {
        let characterWidth = max(9, Int32((style.size * 0.75).rounded()))
        let padding = style.size >= 20 ? Int32(64) : Int32(32)
        return max(220, Int32(value.count) * characterWidth + padding)
    }

    /// Returns the default single-line `STATIC` height for a text style.
    ///
    /// Windows note:
    /// GDI font sizing includes details that are easy to underestimate from a
    /// SwiftUI-like point size. Extra vertical padding prevents descenders such
    /// as "y" and "g" from clipping inside native text controls.
    static func textHeight(for style: WinTextStyle) -> Int32 {
        let lineHeight = Int32((style.size * 1.65).rounded())
        let padding = style.size >= 20 ? Int32(10) : Int32(6)
        return max(style.size >= 20 ? 44 : 28, lineHeight + padding)
    }
}
#endif
