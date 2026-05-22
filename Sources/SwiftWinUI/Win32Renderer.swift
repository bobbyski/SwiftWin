#if os(Windows)
public final class Win32Renderer: Renderer {
    private var instance: HINSTANCE?
    private var window: HWND?
    private var layoutStack: [LayoutState] = []
    private var nextControlID: UInt16 = 100
    private var fonts: [TextStyle: HFONT] = [:]

    public init() {}

    public func beginWindow(_ descriptor: WindowDescriptor) {
        instance = GetModuleHandleW(nil)
        Win32PaintResources.backgroundBrush = CreateSolidBrush(0x00fbf8f7)
        registerWindowClass()

        withWideString("SwiftWinUIWindow") { className in
            withWideString(descriptor.title) { title in
                window = CreateWindowExW(
                    0,
                    className,
                    title,
                    WS_OVERLAPPEDWINDOW,
                    CW_USEDEFAULT,
                    CW_USEDEFAULT,
                    Int32(descriptor.width),
                    Int32(descriptor.height),
                    nil,
                    nil,
                    instance,
                    nil
                )
            }
        }

        layoutStack = [LayoutState(axis: .vertical, x: 32, y: 32, spacing: 10)]
    }

    public func endWindow() {
        guard let window else {
            return
        }

        _ = ShowWindow(window, SW_SHOW)
        _ = UpdateWindow(window)
        runMessageLoop()
    }

    public func beginStack(axis: StackAxis, spacing: Double) {
        let origin = layoutStack.last ?? LayoutState(axis: .vertical, x: 24, y: 24, spacing: 8)
        layoutStack.append(LayoutState(axis: axis, x: origin.x, y: origin.y, spacing: Int32(spacing)))
    }

    public func endStack() {
        guard layoutStack.count > 1, let child = layoutStack.popLast() else {
            return
        }

        let consumedWidth = max(1, child.x - (layoutStack.last?.x ?? 0))
        let consumedHeight = max(1, child.y - (layoutStack.last?.y ?? 0))
        advance(width: consumedWidth, height: consumedHeight)
    }

    public func text(_ value: String, style: TextStyle) {
        if let control = createControl(
            className: "STATIC",
            title: value,
            style: WS_CHILD | WS_VISIBLE | SS_LEFT,
            width: max(220, Int32(value.count * 9 + 32)),
            height: style.size >= 20 ? 36 : 26,
            action: nil
        ) {
            applyFont(style, to: control)
        }
    }

    public func button(_ title: String, action: @escaping () -> Void) {
        if let control = createControl(
            className: "BUTTON",
            title: title,
            style: WS_CHILD | WS_VISIBLE | WS_TABSTOP | BS_PUSHBUTTON,
            width: max(116, Int32(title.count * 9 + 44)),
            height: 36,
            action: action
        ) {
            applyFont(.body, to: control)
        }
    }

    public func spacer() {
        advance(width: 20, height: 20)
    }

    private func registerWindowClass() {
        withWideString("SwiftWinUIWindow") { className in
            var windowClass = WNDCLASSEXW(
                cbSize: UInt32(MemoryLayout<WNDCLASSEXW>.size),
                style: CS_HREDRAW | CS_VREDRAW,
                lpfnWndProc: swiftWinUIWindowProc,
                cbClsExtra: 0,
                cbWndExtra: 0,
                hInstance: instance,
                hIcon: nil,
                hCursor: nil,
                hbrBackground: Win32PaintResources.backgroundBrush,
                lpszMenuName: nil,
                lpszClassName: className,
                hIconSm: nil
            )

            _ = RegisterClassExW(&windowClass)
        }
    }

    private func createControl(
        className: String,
        title: String,
        style: DWORD,
        width: Int32,
        height: Int32,
        action: (() -> Void)?
    ) -> HWND? {
        guard let window, let layout = layoutStack.last else {
            return nil
        }

        let controlID = nextControlID
        nextControlID += 1

        if let action {
            Win32ActionRegistry.actions[controlID] = action
        }

        return withWideString(className) { controlClass in
            withWideString(title) { controlTitle in
                let control = CreateWindowExW(
                    0,
                    controlClass,
                    controlTitle,
                    style,
                    layout.x,
                    layout.y,
                    width,
                    height,
                    window,
                    HMENU(bitPattern: Int(controlID)),
                    instance,
                    nil
                )
                advance(width: width, height: height)
                return control
            }
        }
    }

    private func applyFont(_ style: TextStyle, to control: HWND) {
        let font = fonts[style] ?? createFont(for: style)
        fonts[style] = font
        _ = SendMessageW(control, WM_SETFONT, WPARAM(UInt(bitPattern: font)), 1)
    }

    private func createFont(for style: TextStyle) -> HFONT {
        let height = -Int32(style.size * 1.35)
        let weight: Int32

        switch style.weight {
        case .regular:
            weight = FW_REGULAR
        case .semibold:
            weight = FW_SEMIBOLD
        case .bold:
            weight = FW_BOLD
        }

        return withWideString("Segoe UI") { faceName in
            CreateFontW(
                height,
                0,
                0,
                0,
                weight,
                0,
                0,
                0,
                DEFAULT_CHARSET,
                OUT_DEFAULT_PRECIS,
                CLIP_DEFAULT_PRECIS,
                CLEARTYPE_QUALITY,
                DEFAULT_PITCH | FF_DONTCARE,
                faceName
            )
        }
    }

    private func advance(width: Int32, height: Int32) {
        guard let layout = layoutStack.popLast() else {
            return
        }

        var updated = layout
        switch updated.axis {
        case .horizontal:
            updated.x += width + updated.spacing
            updated.maxCrossAxis = max(updated.maxCrossAxis, height)
        case .vertical:
            updated.y += height + updated.spacing
            updated.maxCrossAxis = max(updated.maxCrossAxis, width)
        }

        layoutStack.append(updated)
    }

    private func runMessageLoop() {
        var message = MSG()
        while GetMessageW(&message, nil, 0, 0) > 0 {
            _ = TranslateMessage(&message)
            _ = DispatchMessageW(&message)
        }
    }
}

private struct LayoutState {
    var axis: StackAxis
    var x: Int32
    var y: Int32
    var spacing: Int32
    var maxCrossAxis: Int32 = 0
}

private enum Win32ActionRegistry {
    nonisolated(unsafe) static var actions: [UInt16: () -> Void] = [:]
}

private enum Win32PaintResources {
    nonisolated(unsafe) static var backgroundBrush: HBRUSH?
}

private func swiftWinUIWindowProc(
    hwnd: HWND?,
    message: UINT,
    wParam: WPARAM,
    lParam: LPARAM
) -> LRESULT {
    switch message {
    case WM_COMMAND:
        let controlID = UInt16(wParam & 0xffff)
        Win32ActionRegistry.actions[controlID]?()
        return 0
    case WM_CTLCOLORSTATIC:
        _ = SetBkMode(HDC(bitPattern: wParam), TRANSPARENT)
        _ = SetTextColor(HDC(bitPattern: wParam), 0x00271811)
        return LRESULT(Int(bitPattern: Win32PaintResources.backgroundBrush))
    case WM_DESTROY:
        PostQuitMessage(0)
        return 0
    default:
        return DefWindowProcW(hwnd, message, wParam, lParam)
    }
}

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

private typealias BOOL = Int32
private typealias DWORD = UInt32
private typealias UINT = UInt32
private typealias WPARAM = UInt
private typealias LPARAM = Int
private typealias LRESULT = Int
private typealias HWND = UnsafeMutableRawPointer
private typealias HINSTANCE = UnsafeMutableRawPointer
private typealias HICON = UnsafeMutableRawPointer
private typealias HCURSOR = UnsafeMutableRawPointer
private typealias HBRUSH = UnsafeMutableRawPointer
private typealias HFONT = UnsafeMutableRawPointer
private typealias HDC = UnsafeMutableRawPointer
private typealias HMENU = UnsafeMutableRawPointer
private typealias WNDPROC = @convention(c) (HWND?, UINT, WPARAM, LPARAM) -> LRESULT

private struct POINT {
    var x: Int32 = 0
    var y: Int32 = 0
}

private struct MSG {
    var hwnd: HWND?
    var message: UINT = 0
    var wParam: WPARAM = 0
    var lParam: LPARAM = 0
    var time: DWORD = 0
    var pt = POINT()
}

private struct WNDCLASSEXW {
    var cbSize: UINT
    var style: UINT
    var lpfnWndProc: WNDPROC?
    var cbClsExtra: Int32
    var cbWndExtra: Int32
    var hInstance: HINSTANCE?
    var hIcon: HICON?
    var hCursor: HCURSOR?
    var hbrBackground: HBRUSH?
    var lpszMenuName: UnsafePointer<UInt16>?
    var lpszClassName: UnsafePointer<UInt16>?
    var hIconSm: HICON?
}

private let CS_VREDRAW: UINT = 0x0001
private let CS_HREDRAW: UINT = 0x0002
private let WS_CHILD: DWORD = 0x40000000
private let WS_VISIBLE: DWORD = 0x10000000
private let WS_TABSTOP: DWORD = 0x00010000
private let WS_OVERLAPPEDWINDOW: DWORD = 0x00cf0000
private let BS_PUSHBUTTON: DWORD = 0x00000000
private let SS_LEFT: DWORD = 0x00000000
private let CW_USEDEFAULT = Int32(bitPattern: 0x80000000)
private let SW_SHOW: Int32 = 5
private let WM_SETFONT: UINT = 0x0030
private let WM_COMMAND: UINT = 0x0111
private let WM_CTLCOLORSTATIC: UINT = 0x0138
private let WM_DESTROY: UINT = 0x0002
private let TRANSPARENT: Int32 = 1
private let FW_REGULAR: Int32 = 400
private let FW_SEMIBOLD: Int32 = 600
private let FW_BOLD: Int32 = 700
private let DEFAULT_CHARSET: DWORD = 1
private let OUT_DEFAULT_PRECIS: DWORD = 0
private let CLIP_DEFAULT_PRECIS: DWORD = 0
private let CLEARTYPE_QUALITY: DWORD = 5
private let DEFAULT_PITCH: DWORD = 0
private let FF_DONTCARE: DWORD = 0

@_silgen_name("GetModuleHandleW")
private func GetModuleHandleW(_ moduleName: UnsafePointer<UInt16>?) -> HINSTANCE?

@_silgen_name("RegisterClassExW")
private func RegisterClassExW(_ windowClass: UnsafePointer<WNDCLASSEXW>) -> UInt16

@_silgen_name("CreateWindowExW")
private func CreateWindowExW(
    _ extendedStyle: DWORD,
    _ className: UnsafePointer<UInt16>,
    _ windowName: UnsafePointer<UInt16>,
    _ style: DWORD,
    _ x: Int32,
    _ y: Int32,
    _ width: Int32,
    _ height: Int32,
    _ parent: HWND?,
    _ menu: HMENU?,
    _ instance: HINSTANCE?,
    _ parameter: UnsafeMutableRawPointer?
) -> HWND?

@_silgen_name("ShowWindow")
private func ShowWindow(_ window: HWND, _ command: Int32) -> BOOL

@_silgen_name("UpdateWindow")
private func UpdateWindow(_ window: HWND) -> BOOL

@_silgen_name("SendMessageW")
private func SendMessageW(
    _ window: HWND,
    _ message: UINT,
    _ wParam: WPARAM,
    _ lParam: LPARAM
) -> LRESULT

@_silgen_name("CreateFontW")
private func CreateFontW(
    _ height: Int32,
    _ width: Int32,
    _ escapement: Int32,
    _ orientation: Int32,
    _ weight: Int32,
    _ italic: DWORD,
    _ underline: DWORD,
    _ strikeOut: DWORD,
    _ charSet: DWORD,
    _ outputPrecision: DWORD,
    _ clipPrecision: DWORD,
    _ quality: DWORD,
    _ pitchAndFamily: DWORD,
    _ faceName: UnsafePointer<UInt16>
) -> HFONT

@_silgen_name("CreateSolidBrush")
private func CreateSolidBrush(_ color: DWORD) -> HBRUSH?

@_silgen_name("SetBkMode")
private func SetBkMode(_ deviceContext: HDC?, _ backgroundMode: Int32) -> Int32

@_silgen_name("SetTextColor")
private func SetTextColor(_ deviceContext: HDC?, _ color: DWORD) -> DWORD

@_silgen_name("GetMessageW")
private func GetMessageW(
    _ message: UnsafeMutablePointer<MSG>,
    _ window: HWND?,
    _ minimumMessage: UINT,
    _ maximumMessage: UINT
) -> BOOL

@_silgen_name("TranslateMessage")
private func TranslateMessage(_ message: UnsafePointer<MSG>) -> BOOL

@_silgen_name("DispatchMessageW")
private func DispatchMessageW(_ message: UnsafePointer<MSG>) -> LRESULT

@_silgen_name("DefWindowProcW")
private func DefWindowProcW(
    _ window: HWND?,
    _ message: UINT,
    _ wParam: WPARAM,
    _ lParam: LPARAM
) -> LRESULT

@_silgen_name("PostQuitMessage")
private func PostQuitMessage(_ exitCode: Int32)
#endif
