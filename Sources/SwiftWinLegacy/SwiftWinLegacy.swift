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

/// Marker protocol for imperative UI elements.
///
/// The first version uses class-based elements because the traditional API is
/// expected to gain identity, mutation, and event hooks over time.
public protocol WinElement: AnyObject {}

/// Protocol for objects that can run a traditional SwiftWin window.
///
/// Keeping this as a protocol lets tests, future hosted runtimes, or alternate
/// app shells provide their own runner without changing `WinApplication` users.
public protocol WinApplicationRunning: AnyObject {
    /// Runs a window until the backing runtime exits.
    func run(_ window: WinWindow)
}

/// Protocol for elements that own an ordered list of child elements.
///
/// Containers expose their children read-only to callers while still providing
/// an explicit mutation method. This keeps the public API simple and leaves
/// room for future validation when layout rules become more complex.
public protocol WinContainer: WinElement {
    /// Ordered child elements.
    var children: [WinElement] { get }
    /// Appends a child element.
    func add(_ element: WinElement)
}

/// Protocol for elements that display mutable text.
///
/// Custom controls can conform to this when they want to participate in shared
/// text styling, accessibility, or future data binding code.
public protocol WinTextDisplaying: WinElement {
    /// Displayed text.
    var value: String { get set }
    /// Text style used by the native runtime.
    var style: WinTextStyle { get set }
}

/// Protocol for controls with a visible title.
public protocol WinTitledControl: WinElement {
    /// Text shown by the control.
    var title: String { get set }
}

/// Protocol for controls that invoke an action.
public protocol WinActionControl: WinElement {
    /// Closure invoked by native event routing.
    var action: () -> Void { get set }
}

/// Protocol for button-like controls.
///
/// `WinButton` is the first implementation, but this keeps room for custom
/// command buttons, toolbar buttons, or owner-provided button controls.
public protocol WinButtonDisplaying: WinTitledControl, WinActionControl {
    /// Visual role for the button.
    var style: WinButtonStyle { get set }
}

/// Axis for traditional stack layout.
public enum WinAxis: Sendable {
    /// Children flow left to right.
    case horizontal
    /// Children flow top to bottom.
    case vertical
}

/// Imperative stack container.
///
/// `WinStack` currently maps to simple direct placement in the Win32 runtime.
/// It is intended to become the shared layout primitive that SwiftWinUI stacks
/// can wrap.
public final class WinStack: WinContainer {
    /// Stack direction.
    public var axis: WinAxis
    /// Spacing between child elements.
    public var spacing: Double
    /// Ordered child elements.
    public private(set) var children: [WinElement] = []

    /// Creates a stack.
    public init(axis: WinAxis, spacing: Double = 8) {
        self.axis = axis
        self.spacing = spacing
    }

    /// Appends a child element.
    public func add(_ element: WinElement) {
        children.append(element)
    }
}

/// Static text element in the traditional API.
public final class WinText: WinTextDisplaying {
    /// Displayed text.
    public var value: String
    /// Text style used by the native runtime.
    public var style: WinTextStyle

    /// Creates text.
    public init(_ value: String, style: WinTextStyle = .body) {
        self.value = value
        self.style = style
    }
}

/// Font description for `WinText`.
public struct WinTextStyle: Sendable, Hashable {
    /// Font size in prototype points/pixels.
    public var size: Double
    /// Font weight.
    public var weight: WinFontWeight

    /// Large title text.
    public static let title = WinTextStyle(size: 24, weight: .semibold)
    /// Default body text.
    public static let body = WinTextStyle(size: 14, weight: .regular)
    /// Small caption text.
    public static let caption = WinTextStyle(size: 12, weight: .regular)

    /// Creates a text style.
    public init(size: Double, weight: WinFontWeight = .regular) {
        self.size = size
        self.weight = weight
    }
}

/// Supported font weights.
public enum WinFontWeight: Sendable, Hashable {
    /// Normal text weight.
    case regular
    /// Medium emphasis.
    case semibold
    /// Strong emphasis.
    case bold
}

/// Imperative button element.
public final class WinButton: WinButtonDisplaying {
    /// Text shown on the button.
    public var title: String
    /// Visual role for the button.
    public var style: WinButtonStyle
    /// Closure invoked when native command routing reports a click.
    public var action: () -> Void

    /// Creates a button.
    public init(_ title: String, style: WinButtonStyle = .secondary, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }
}

/// Button visual role.
public enum WinButtonStyle: Sendable, Hashable {
    /// Main action button.
    case primary
    /// Standard secondary action button.
    case secondary
}

/// Imperative spacer element.
///
/// Current behavior is fixed spacing. Flexible layout behavior is planned once
/// the shared layout engine exists.
public final class WinSpacer: WinElement {
    /// Creates a spacer.
    public init() {}
}

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

/// Diagnostic renderer for the traditional element tree.
///
/// This keeps `SwiftWinLegacy` usable from non-Windows environments and gives
/// us a future hook for snapshot tests.
private final class ConsoleLegacyRenderer {
    private var indent = 0

    func render(_ window: WinWindow) {
        write("WinWindow(title: \(window.title), size: \(window.width)x\(window.height))")
        indent += 1
        if let content = window.content {
            render(content)
        }
        indent -= 1
    }

    /// Recursively prints a legacy element.
    private func render(_ element: WinElement) {
        switch element {
        case let stack as WinStack:
            write("WinStack(axis: \(stack.axis), spacing: \(stack.spacing))")
            indent += 1
            stack.children.forEach(render)
            indent -= 1
        case let text as WinText:
            write("WinText(\"\(text.value)\", size: \(text.style.size), weight: \(text.style.weight))")
        case let button as WinButton:
            write("WinButton(\"\(button.title)\", style: \(button.style))")
        case is WinSpacer:
            write("WinSpacer()")
        default:
            write("UnknownElement()")
        }
    }

    /// Writes an indented diagnostic line.
    private func write(_ value: String) {
        print(String(repeating: "  ", count: indent) + value)
    }
}

#if os(Windows)
/// Native Win32 runner for the traditional API.
///
/// Implementation decision:
/// This type currently owns both tree traversal and native control creation.
/// That is simple for the first milestone, but it should eventually be split
/// into platform declarations, layout, resource management, and control hosts.
private final class Win32ApplicationRunner {
    private var instance: HINSTANCE?
    private var window: HWND?
    private var layoutStack: [LayoutState] = []
    private var nextControlID: UInt16 = 100
    private var fonts: [WinTextStyle: HFONT] = [:]

    /// Creates native controls from a `WinWindow` and starts the message loop.
    func run(_ descriptor: WinWindow) {
        instance = GetModuleHandleW(nil)
        Win32PaintResources.backgroundBrush = CreateSolidBrush(0x00fbf8f7)
        registerWindowClass()
        createWindow(descriptor)
        layoutStack = [LayoutState(axis: .vertical, x: 36, y: 34, spacing: 12)]

        if let content = descriptor.content {
            render(content)
        }

        guard let window else {
            return
        }

        _ = ShowWindow(window, SW_SHOW)
        _ = UpdateWindow(window)
        runMessageLoop()
    }

    /// Creates the top-level HWND for a window descriptor.
    private func createWindow(_ descriptor: WinWindow) {
        withWideString("SwiftWinLegacyWindow") { className in
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
    }

    /// Traverses the imperative element tree and creates native controls.
    private func render(_ element: WinElement) {
        switch element {
        case let stack as WinStack:
            beginStack(axis: stack.axis, spacing: stack.spacing)
            stack.children.forEach(render)
            endStack()
        case let text as WinText:
            createText(text.value, style: text.style)
        case let button as WinButton:
            createButton(button.title, style: button.style, action: button.action)
        case is WinSpacer:
            advance(width: 20, height: 20)
        default:
            break
        }
    }

    /// Pushes a stack layout context.
    ///
    /// Implementation note:
    /// This is a direct-placement prototype, not a real layout engine. Each
    /// stack records its starting point and advances coordinates as children
    /// are created.
    private func beginStack(axis: WinAxis, spacing: Double) {
        let origin = layoutStack.last ?? LayoutState(axis: .vertical, x: 36, y: 34, spacing: 12)
        layoutStack.append(LayoutState(axis: axis, x: origin.x, y: origin.y, spacing: Int32(spacing)))
    }

    /// Pops a stack context and advances its parent by the consumed size.
    private func endStack() {
        guard layoutStack.count > 1, let child = layoutStack.popLast() else {
            return
        }

        let consumedWidth = max(child.maxCrossAxis, child.x - child.originX)
        let consumedHeight = max(child.maxCrossAxis, child.y - child.originY)
        advance(width: consumedWidth, height: consumedHeight)
    }

    /// Creates a native static text control.
    private func createText(_ value: String, style: WinTextStyle) {
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

    /// Creates an owner-drawn native button.
    ///
    /// Implementation note:
    /// Win32's stock buttons did not provide enough visual differentiation for
    /// our prototype. `BS_OWNERDRAW` keeps native click/focus behavior while
    /// letting us paint primary and secondary appearances ourselves.
    private func createButton(_ title: String, style buttonStyle: WinButtonStyle, action: @escaping () -> Void) {
        if let control = createControl(
            className: "BUTTON",
            title: title,
            style: WS_CHILD | WS_VISIBLE | WS_TABSTOP | BS_OWNERDRAW,
            width: max(buttonStyle == .primary ? 136 : 116, Int32(title.count * 9 + 48)),
            height: 40,
            action: action,
            button: ButtonRenderState(title: title, style: buttonStyle)
        ) {
            applyFont(.body, to: control)
        }
    }

    /// Registers the window class used by SwiftWinLegacy windows.
    private func registerWindowClass() {
        withWideString("SwiftWinLegacyWindow") { className in
            var windowClass = WNDCLASSEXW(
                cbSize: UInt32(MemoryLayout<WNDCLASSEXW>.size),
                style: CS_HREDRAW | CS_VREDRAW,
                lpfnWndProc: swiftWinLegacyWindowProc,
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

    /// Creates a child HWND and registers any associated action/drawing state.
    ///
    /// Implementation note:
    /// Many Win32 controls are child windows. The returned `HWND` represents
    /// the native control, not just a lightweight view object.
    private func createControl(
        className: String,
        title: String,
        style: DWORD,
        width: Int32,
        height: Int32,
        action: (() -> Void)?,
        button: ButtonRenderState? = nil
    ) -> HWND? {
        guard let window, let layout = layoutStack.last else {
            return nil
        }

        let controlID = nextControlID
        nextControlID += 1

        if let action {
            Win32ActionRegistry.actions[controlID] = action
        }
        if let button {
            Win32ActionRegistry.buttons[UInt32(controlID)] = button
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

    /// Applies a cached Segoe UI font to a native control.
    private func applyFont(_ style: WinTextStyle, to control: HWND) {
        let font = fonts[style] ?? createFont(for: style)
        fonts[style] = font
        _ = SendMessageW(control, WM_SETFONT, WPARAM(UInt(bitPattern: font)), 1)
    }

    /// Creates a GDI font for the given text style.
    ///
    /// Implementation note:
    /// Negative font heights request character height rather than cell height,
    /// which is the common Win32 path for UI fonts.
    private func createFont(for style: WinTextStyle) -> HFONT {
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

    /// Advances the current layout context after placing an element.
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

    /// Runs the standard Win32 message loop.
    ///
    /// Apple developer note:
    /// This is the explicit event pump. Windows apps typically call
    /// `GetMessage`, `TranslateMessage`, and `DispatchMessage` until the window
    /// posts quit.
    private func runMessageLoop() {
        var message = MSG()
        while GetMessageW(&message, nil, 0, 0) > 0 {
            _ = TranslateMessage(&message)
            _ = DispatchMessageW(&message)
        }
    }
}

/// Current direct-placement layout context.
private struct LayoutState {
    var axis: WinAxis
    var originX: Int32
    var originY: Int32
    var x: Int32
    var y: Int32
    var spacing: Int32
    var maxCrossAxis: Int32 = 0

    init(axis: WinAxis, x: Int32, y: Int32, spacing: Int32) {
        self.axis = axis
        self.originX = x
        self.originY = y
        self.x = x
        self.y = y
        self.spacing = spacing
    }
}

/// Global action/drawing registries keyed by Win32 control IDs.
///
/// Implementation note:
/// This prototype uses process-global mutable state because the C window
/// procedure does not receive the Swift runner instance directly. A future
/// version should attach per-window state with `GWLP_USERDATA` or a similar
/// handle-to-object mapping.
private enum Win32ActionRegistry {
    nonisolated(unsafe) static var actions: [UInt16: () -> Void] = [:]
    nonisolated(unsafe) static var buttons: [UInt32: ButtonRenderState] = [:]
}

/// Owner-draw metadata for a button.
private struct ButtonRenderState {
    var title: String
    var style: WinButtonStyle
}

/// Shared paint resources for the current Win32 prototype.
private enum Win32PaintResources {
    nonisolated(unsafe) static var backgroundBrush: HBRUSH?
}

/// Window procedure for SwiftWinLegacy windows.
///
/// This is where Win32 messages are translated back into Swift behavior.
private func swiftWinLegacyWindowProc(
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
    case WM_DRAWITEM:
        guard let drawItem = UnsafePointer<DRAWITEMSTRUCT>(bitPattern: lParam)?.pointee else {
            return 0
        }
        drawButton(drawItem)
        return 1
    case WM_DESTROY:
        PostQuitMessage(0)
        return 0
    default:
        return DefWindowProcW(hwnd, message, wParam, lParam)
    }
}

/// Paints an owner-drawn button.
///
/// Implementation note:
/// GDI color values are `COLORREF` in `0x00bbggrr` order, which looks odd if
/// you are used to CSS/AppKit-style RGB notation.
private func drawButton(_ item: DRAWITEMSTRUCT) {
    guard let deviceContext = item.hDC,
          let button = Win32ActionRegistry.buttons[item.CtlID] else {
        return
    }

    let isPressed = (item.itemState & ODS_SELECTED) != 0
    let isFocused = (item.itemState & ODS_FOCUS) != 0
    let palette = buttonPalette(for: button.style, isPressed: isPressed)
    let fillBrush = CreateSolidBrush(palette.fill)
    let borderPen = CreatePen(PS_SOLID, isFocused ? 2 : 1, palette.border)
    let oldBrush = SelectObject(deviceContext, fillBrush)
    let oldPen = SelectObject(deviceContext, borderPen)

    var rect = item.rcItem
    let offset: Int32 = isPressed ? 1 : 0
    _ = RoundRect(
        deviceContext,
        rect.left + offset,
        rect.top + offset,
        rect.right - 1 + offset,
        rect.bottom - 1 + offset,
        10,
        10
    )

    if let oldBrush {
        _ = SelectObject(deviceContext, oldBrush)
    }
    if let oldPen {
        _ = SelectObject(deviceContext, oldPen)
    }
    _ = DeleteObject(fillBrush)
    _ = DeleteObject(borderPen)

    _ = SetBkMode(deviceContext, TRANSPARENT)
    _ = SetTextColor(deviceContext, palette.text)

    rect.left += 12 + offset
    rect.right -= 12 - offset
    rect.top += offset
    rect.bottom += offset

    withWideString(button.title) { title in
        _ = DrawTextW(deviceContext, title, -1, &rect, DT_CENTER | DT_VCENTER | DT_SINGLELINE)
    }
}

/// Returns owner-draw colors for the current button state.
private func buttonPalette(for style: WinButtonStyle, isPressed: Bool) -> ButtonPalette {
    switch style {
    case .primary:
        return ButtonPalette(fill: isPressed ? 0x00c8521d : 0x00eb6325, border: isPressed ? 0x00b84818 : 0x00d95b20, text: 0x00ffffff)
    case .secondary:
        return ButtonPalette(fill: isPressed ? 0x00f0ecea : 0x00ffffff, border: 0x00ddd4cf, text: 0x00271811)
    }
}

/// Owner-draw color palette.
private struct ButtonPalette {
    var fill: DWORD
    var border: DWORD
    var text: DWORD
}

// Win32 typealiases and declarations.
//
// Implementation note:
// These hand declarations avoid importing `WinSDK`, which has been unreliable
// in the current ARM64 Windows Swift snapshot. They should eventually move into
// a private platform shim or generated bindings.
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
private typealias HGDIOBJ = UnsafeMutableRawPointer
private typealias HPEN = UnsafeMutableRawPointer
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

private struct RECT {
    var left: Int32 = 0
    var top: Int32 = 0
    var right: Int32 = 0
    var bottom: Int32 = 0
}

private struct DRAWITEMSTRUCT {
    var CtlType: UINT
    var CtlID: UINT
    var itemID: UINT
    var itemAction: UINT
    var itemState: UINT
    var hwndItem: HWND?
    var hDC: HDC?
    var rcItem: RECT
    var itemData: UInt
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
private let BS_OWNERDRAW: DWORD = 0x0000000b
private let SS_LEFT: DWORD = 0x00000000
private let CW_USEDEFAULT = Int32(bitPattern: 0x80000000)
private let SW_SHOW: Int32 = 5
private let WM_SETFONT: UINT = 0x0030
private let WM_COMMAND: UINT = 0x0111
private let WM_DRAWITEM: UINT = 0x002b
private let WM_CTLCOLORSTATIC: UINT = 0x0138
private let WM_DESTROY: UINT = 0x0002
private let ODS_SELECTED: UINT = 0x0001
private let ODS_FOCUS: UINT = 0x0010
private let TRANSPARENT: Int32 = 1
private let PS_SOLID: Int32 = 0
private let FW_REGULAR: Int32 = 400
private let FW_SEMIBOLD: Int32 = 600
private let FW_BOLD: Int32 = 700
private let DEFAULT_CHARSET: DWORD = 1
private let OUT_DEFAULT_PRECIS: DWORD = 0
private let CLIP_DEFAULT_PRECIS: DWORD = 0
private let CLEARTYPE_QUALITY: DWORD = 5
private let DEFAULT_PITCH: DWORD = 0
private let FF_DONTCARE: DWORD = 0
private let DT_CENTER: UINT = 0x00000001
private let DT_VCENTER: UINT = 0x00000004
private let DT_SINGLELINE: UINT = 0x00000020
private let MB_OK: UINT = 0x00000000
private let MB_ICONINFORMATION: UINT = 0x00000040

/// Provides a temporary null-terminated UTF-16 pointer for Win32 APIs.
private func withWideString<Result>(_ value: String, _ body: (UnsafePointer<UInt16>) -> Result) -> Result {
    var wideValue = Array(value.utf16)
    wideValue.append(0)
    return wideValue.withUnsafeBufferPointer { buffer in
        body(buffer.baseAddress!)
    }
}

@_silgen_name("GetModuleHandleW")
private func GetModuleHandleW(_ moduleName: UnsafePointer<UInt16>?) -> HINSTANCE?
@_silgen_name("RegisterClassExW")
private func RegisterClassExW(_ windowClass: UnsafePointer<WNDCLASSEXW>) -> UInt16
@_silgen_name("CreateWindowExW")
private func CreateWindowExW(_ extendedStyle: DWORD, _ className: UnsafePointer<UInt16>, _ windowName: UnsafePointer<UInt16>, _ style: DWORD, _ x: Int32, _ y: Int32, _ width: Int32, _ height: Int32, _ parent: HWND?, _ menu: HMENU?, _ instance: HINSTANCE?, _ parameter: UnsafeMutableRawPointer?) -> HWND?
@_silgen_name("ShowWindow")
private func ShowWindow(_ window: HWND, _ command: Int32) -> BOOL
@_silgen_name("UpdateWindow")
private func UpdateWindow(_ window: HWND) -> BOOL
@_silgen_name("SendMessageW")
private func SendMessageW(_ window: HWND, _ message: UINT, _ wParam: WPARAM, _ lParam: LPARAM) -> LRESULT
@_silgen_name("CreateFontW")
private func CreateFontW(_ height: Int32, _ width: Int32, _ escapement: Int32, _ orientation: Int32, _ weight: Int32, _ italic: DWORD, _ underline: DWORD, _ strikeOut: DWORD, _ charSet: DWORD, _ outputPrecision: DWORD, _ clipPrecision: DWORD, _ quality: DWORD, _ pitchAndFamily: DWORD, _ faceName: UnsafePointer<UInt16>) -> HFONT
@_silgen_name("CreateSolidBrush")
private func CreateSolidBrush(_ color: DWORD) -> HBRUSH?
@_silgen_name("SetBkMode")
private func SetBkMode(_ deviceContext: HDC?, _ backgroundMode: Int32) -> Int32
@_silgen_name("SetTextColor")
private func SetTextColor(_ deviceContext: HDC?, _ color: DWORD) -> DWORD
@_silgen_name("CreatePen")
private func CreatePen(_ style: Int32, _ width: Int32, _ color: DWORD) -> HPEN?
@_silgen_name("SelectObject")
private func SelectObject(_ deviceContext: HDC, _ object: HGDIOBJ?) -> HGDIOBJ?
@_silgen_name("DeleteObject")
private func DeleteObject(_ object: HGDIOBJ?) -> BOOL
@_silgen_name("RoundRect")
private func RoundRect(_ deviceContext: HDC, _ left: Int32, _ top: Int32, _ right: Int32, _ bottom: Int32, _ width: Int32, _ height: Int32) -> BOOL
@_silgen_name("DrawTextW")
private func DrawTextW(_ deviceContext: HDC, _ text: UnsafePointer<UInt16>, _ count: Int32, _ rect: UnsafeMutablePointer<RECT>, _ format: UINT) -> Int32
@_silgen_name("GetMessageW")
private func GetMessageW(_ message: UnsafeMutablePointer<MSG>, _ window: HWND?, _ minimumMessage: UINT, _ maximumMessage: UINT) -> BOOL
@_silgen_name("TranslateMessage")
private func TranslateMessage(_ message: UnsafePointer<MSG>) -> BOOL
@_silgen_name("DispatchMessageW")
private func DispatchMessageW(_ message: UnsafePointer<MSG>) -> LRESULT
@_silgen_name("DefWindowProcW")
private func DefWindowProcW(_ window: HWND?, _ message: UINT, _ wParam: WPARAM, _ lParam: LPARAM) -> LRESULT
@_silgen_name("PostQuitMessage")
private func PostQuitMessage(_ exitCode: Int32)
@_silgen_name("MessageBoxW")
private func MessageBoxW(_ window: HWND?, _ text: UnsafePointer<UInt16>, _ caption: UnsafePointer<UInt16>, _ type: UINT) -> Int32
#endif
