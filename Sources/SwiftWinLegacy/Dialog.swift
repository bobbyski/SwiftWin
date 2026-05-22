/// Traditional dialog facade.
public enum WinDialog {
    /// Shows an informational native dialog on Windows.
    ///
    /// Non-Windows fallback prints to standard output.
    public static func show(title: String, message: String) {
        #if os(Windows)
        withWideString(title) { titlePointer in
            withWideString(message) { messagePointer in
                _ = MessageBoxW(nil, messagePointer, titlePointer, MB_OK | MB_ICONINFORMATION)
            }
        }
        #else
        print("\(title): \(message)")
        #endif
    }
}
