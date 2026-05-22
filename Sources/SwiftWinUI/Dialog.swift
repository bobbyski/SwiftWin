public enum Dialog {
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

#if os(Windows)
private typealias UINT = UInt32
private typealias HWND = UnsafeMutableRawPointer

private let MB_OK: UINT = 0x00000000
private let MB_ICONINFORMATION: UINT = 0x00000040

private func withWideString<Result>(
    _ value: String,
    _ body: (UnsafePointer<UInt16>) -> Result
) -> Result {
    var wideValue = Array(value.utf16)
    wideValue.append(0)
    return wideValue.withUnsafeBufferPointer { buffer in
        body(buffer.baseAddress!)
    }
}

@_silgen_name("MessageBoxW")
private func MessageBoxW(
    _ window: HWND?,
    _ text: UnsafePointer<UInt16>,
    _ caption: UnsafePointer<UInt16>,
    _ type: UINT
) -> Int32
#endif
