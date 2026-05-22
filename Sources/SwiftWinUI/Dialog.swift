import SwiftWinLegacy

/// SwiftWinUI dialog facade.
///
/// This wrapper keeps SwiftWinUI user code independent from the traditional
/// layer while still delegating implementation to `SwiftWinLegacy.WinDialog`.
public enum Dialog {
    /// Shows a native informational dialog on Windows.
    ///
    /// Non-Windows fallback currently prints to the console through
    /// `SwiftWinLegacy`.
    public static func show(title: String, message: String) {
        WinDialog.show(title: title, message: message)
    }
}
