#if os(Windows)
public final class Win32Renderer: Renderer {
    private var instance: HINSTANCE?
    private var window: HWND?
    private var layoutStack: [LayoutState] = []
    private var nextControlID: UInt16 = 100

    public init() {}

    public func beginWindow(_ descriptor: WindowDescriptor) {
        instance = GetModuleHandleW(nil)
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

        layoutStack = [LayoutState(axis: .vertical, x: 24, y: 24, spacing: 8)]
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
        createControl(
            className: "STATIC",
            title: value,
            style: WS_CHILD | WS_VISIBLE,
            width: max(160, Int32(value.count * 8 + 24)),
            height: style.size >= 20 ? 32 : 24,
            action: nil
        )
    }

    public func button(_ title: String, action: @escaping () -> Void) {
        createControl(
            className: "BUTTON",
            title: title,
            style: WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
            width: max(96, Int32(title.count * 8 + 36)),
            height: 32,
            action: action
        )
    }

    public func spacer() {
        advance(width: 16, height: 16)
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
                hbrBackground: HBRUSH(bitPattern: Int(COLOR_WINDOW + 1)),
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
    ) {
        guard let window, let layout = layoutStack.last else {
            return
        }

        let controlID = nextControlID
        nextControlID += 1

        if let action {
            Win32ActionRegistry.actions[controlID] = action
        }

        withWideString(className) { controlClass in
            withWideString(title) { controlTitle in
                _ = CreateWindowExW(
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
            }
        }

        advance(width: width, height: height)
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
private let WS_OVERLAPPEDWINDOW: DWORD = 0x00cf0000
private let BS_PUSHBUTTON: DWORD = 0x00000000
private let COLOR_WINDOW: UInt32 = 5
private let CW_USEDEFAULT = Int32(bitPattern: 0x80000000)
private let SW_SHOW: Int32 = 5
private let WM_COMMAND: UINT = 0x0111
private let WM_DESTROY: UINT = 0x0002

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
