#if os(Windows)
// Win32 typealiases and declarations.
//
// Implementation note:
// These hand declarations avoid importing `WinSDK`, which has been unreliable
// in the current ARM64 Windows Swift snapshot. They should eventually move into
// a private platform shim or generated bindings.
typealias BOOL = Int32
typealias DWORD = UInt32
typealias UINT = UInt32
typealias WPARAM = UInt
typealias LPARAM = Int
typealias LRESULT = Int
typealias HWND = UnsafeMutableRawPointer
typealias HINSTANCE = UnsafeMutableRawPointer
typealias HICON = UnsafeMutableRawPointer
typealias HCURSOR = UnsafeMutableRawPointer
typealias HBRUSH = UnsafeMutableRawPointer
typealias HFONT = UnsafeMutableRawPointer
typealias HDC = UnsafeMutableRawPointer
typealias HGDIOBJ = UnsafeMutableRawPointer
typealias HPEN = UnsafeMutableRawPointer
typealias HRGN = UnsafeMutableRawPointer
typealias HANDLE = UnsafeMutableRawPointer
typealias HMENU = UnsafeMutableRawPointer
typealias WNDPROC = @convention(c) (HWND?, UINT, WPARAM, LPARAM) -> LRESULT

struct POINT {
    var x: Int32 = 0
    var y: Int32 = 0
}

struct MSG {
    var hwnd: HWND?
    var message: UINT = 0
    var wParam: WPARAM = 0
    var lParam: LPARAM = 0
    var time: DWORD = 0
    var pt = POINT()
}

struct RECT {
    var left: Int32 = 0
    var top: Int32 = 0
    var right: Int32 = 0
    var bottom: Int32 = 0
}

struct DRAWITEMSTRUCT {
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

struct WNDCLASSEXW {
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

struct INITCOMMONCONTROLSEX {
    var dwSize: DWORD
    var dwICC: DWORD
}

struct TRACKMOUSEEVENT {
    var cbSize: DWORD
    var dwFlags: DWORD
    var hwndTrack: HWND?
    var dwHoverTime: DWORD
}

struct SYSTEMTIME {
    var wYear: UInt16 = 0
    var wMonth: UInt16 = 0
    var wDayOfWeek: UInt16 = 0
    var wDay: UInt16 = 0
    var wHour: UInt16 = 0
    var wMinute: UInt16 = 0
    var wSecond: UInt16 = 0
    var wMilliseconds: UInt16 = 0
}

struct NMHDR {
    var hwndFrom: HWND?
    var idFrom: UInt
    var code: Int32
}

struct NMDATETIMECHANGE {
    var nmhdr: NMHDR
    var dwFlags: DWORD
    var st: SYSTEMTIME
}

let CS_VREDRAW: UINT = 0x0001
let CS_HREDRAW: UINT = 0x0002
let WS_CHILD: DWORD = 0x40000000
let WS_VISIBLE: DWORD = 0x10000000
let WS_TABSTOP: DWORD = 0x00010000
let WS_GROUP: DWORD = 0x00020000
let WS_VSCROLL: DWORD = 0x00200000
let WS_BORDER: DWORD = 0x00800000
let WS_OVERLAPPEDWINDOW: DWORD = 0x00cf0000
let WS_EX_CONTROLPARENT: DWORD = 0x00010000
let BS_OWNERDRAW: DWORD = 0x0000000b
let BS_AUTOCHECKBOX: DWORD = 0x00000003
let BS_AUTORADIOBUTTON: DWORD = 0x00000009
let SS_OWNERDRAW: DWORD = 0x0000000d
let ES_MULTILINE: DWORD = 0x00000004
let ES_AUTOVSCROLL: DWORD = 0x00000040
let ES_AUTOHSCROLL: DWORD = 0x00000080
let ES_PASSWORD: DWORD = 0x00000020
let ES_WANTRETURN: DWORD = 0x00001000
let SS_LEFT: DWORD = 0x00000000
let SS_CENTER: DWORD = 0x00000001
let ICC_BAR_CLASSES: DWORD = 0x00000004
let ICC_PROGRESS_CLASS: DWORD = 0x00000020
let ICC_DATE_CLASSES: DWORD = 0x00000100
let CW_USEDEFAULT = Int32(bitPattern: 0x80000000)
let SW_SHOW: Int32 = 5
let SW_SHOWNORMAL: Int32 = 1
let WM_SETFONT: UINT = 0x0030
let WM_COMMAND: UINT = 0x0111
let WM_HSCROLL: UINT = 0x0114
let WM_NOTIFY: UINT = 0x004e
let WM_DRAWITEM: UINT = 0x002b
let WM_CTLCOLOREDIT: UINT = 0x0133
let WM_CTLCOLORSTATIC: UINT = 0x0138
let WM_SIZE: UINT = 0x0005
let WM_MOUSEMOVE: UINT = 0x0200
let WM_MOUSEWHEEL: UINT = 0x020a
let WM_MOUSELEAVE: UINT = 0x02a3
let WM_KEYDOWN: UINT = 0x0100
let WM_SETFOCUS: UINT = 0x0007
let WM_KILLFOCUS: UINT = 0x0008
let WM_DESTROY: UINT = 0x0002
let EM_SETCUEBANNER: UINT = 0x1501
let EN_CHANGE: UInt16 = 0x0300
let BN_CLICKED: UInt16 = 0
let BM_GETCHECK: UINT = 0x00f0
let BM_SETCHECK: UINT = 0x00f1
let BST_UNCHECKED: WPARAM = 0
let BST_CHECKED: WPARAM = 1
let TBS_AUTOTICKS: DWORD = 0x00000001
let WM_USER: UINT = 0x0400
let TBM_GETPOS: UINT = WM_USER
let TBM_SETPOS: UINT = WM_USER + 5
let TBM_SETRANGE: UINT = WM_USER + 6
let PBM_SETRANGE: UINT = WM_USER + 1
let PBM_SETPOS: UINT = WM_USER + 2
let DTM_FIRST: UINT = 0x1000
let DTM_GETSYSTEMTIME: UINT = DTM_FIRST + 1
let DTM_SETSYSTEMTIME: UINT = DTM_FIRST + 2
let DTM_SETFORMATW: UINT = DTM_FIRST + 50
let DTN_DATETIMECHANGE: Int32 = -759
let GDT_VALID: WPARAM = 0
let DTS_SHORTDATEFORMAT: DWORD = 0x0000
let ODS_SELECTED: UINT = 0x0001
let ODS_DISABLED: UINT = 0x0004
let ODS_FOCUS: UINT = 0x0010
let ODS_HOTLIGHT: UINT = 0x0040
let TRANSPARENT: Int32 = 1
let PS_SOLID: Int32 = 0
let NULL_BRUSH: Int32 = 5
let NULL_PEN: Int32 = 8
let WHITE_BRUSH: Int32 = 0
let FW_REGULAR: Int32 = 400
let FW_SEMIBOLD: Int32 = 600
let FW_BOLD: Int32 = 700
let DEFAULT_CHARSET: DWORD = 1
let OUT_DEFAULT_PRECIS: DWORD = 0
let CLIP_DEFAULT_PRECIS: DWORD = 0
let CLEARTYPE_QUALITY: DWORD = 5
let DEFAULT_PITCH: DWORD = 0
let FF_DONTCARE: DWORD = 0
let DT_CENTER: UINT = 0x00000001
let DT_VCENTER: UINT = 0x00000004
let DT_SINGLELINE: UINT = 0x00000020
let MB_OK: UINT = 0x00000000
let MB_ICONINFORMATION: UINT = 0x00000040
let GWLP_WNDPROC: Int32 = -4
let TME_LEAVE: DWORD = 0x00000002
let HOVER_DEFAULT: DWORD = 0xffffffff
let VK_TAB: WPARAM = 0x09
let VK_SHIFT: Int32 = 0x10
let RDW_INVALIDATE: UINT = 0x0001
let RDW_ERASE: UINT = 0x0004
let RDW_ALLCHILDREN: UINT = 0x0080
let RDW_UPDATENOW: UINT = 0x0100

/// Provides a temporary null-terminated UTF-16 pointer for Win32 APIs.
func withWideString<Result>(_ value: String, _ body: (UnsafePointer<UInt16>) -> Result) -> Result {
    var wideValue = Array(value.utf16)
    wideValue.append(0)
    return wideValue.withUnsafeBufferPointer { buffer in
        body(buffer.baseAddress!)
    }
}

/// Packs two signed 16-bit values into a Win32 `LPARAM`.
func makeLong(low: Int, high: Int) -> LPARAM {
    let lowWord = UInt32(UInt16(bitPattern: Int16(clamping: low)))
    let highWord = UInt32(UInt16(bitPattern: Int16(clamping: high))) << 16
    return LPARAM(lowWord | highWord)
}

@_silgen_name("GetModuleHandleW")
func GetModuleHandleW(_ moduleName: UnsafePointer<UInt16>?) -> HINSTANCE?
@_silgen_name("InitCommonControlsEx")
func InitCommonControlsEx(_ controls: UnsafeMutablePointer<INITCOMMONCONTROLSEX>) -> BOOL
@_silgen_name("SetProcessDpiAwarenessContext")
func SetProcessDpiAwarenessContext(_ value: HANDLE?) -> BOOL
@_silgen_name("SetProcessDPIAware")
func SetProcessDPIAware() -> BOOL
@_silgen_name("RegisterClassExW")
func RegisterClassExW(_ windowClass: UnsafePointer<WNDCLASSEXW>) -> UInt16
@_silgen_name("CreateWindowExW")
func CreateWindowExW(_ extendedStyle: DWORD, _ className: UnsafePointer<UInt16>, _ windowName: UnsafePointer<UInt16>, _ style: DWORD, _ x: Int32, _ y: Int32, _ width: Int32, _ height: Int32, _ parent: HWND?, _ menu: HMENU?, _ instance: HINSTANCE?, _ parameter: UnsafeMutableRawPointer?) -> HWND?
@_silgen_name("ShowWindow")
func ShowWindow(_ window: HWND, _ command: Int32) -> BOOL
@_silgen_name("UpdateWindow")
func UpdateWindow(_ window: HWND) -> BOOL
@_silgen_name("InvalidateRect")
func InvalidateRect(_ window: HWND?, _ rect: UnsafePointer<RECT>?, _ erase: BOOL) -> BOOL
@_silgen_name("RedrawWindow")
func RedrawWindow(_ window: HWND?, _ updateRect: UnsafePointer<RECT>?, _ updateRegion: HRGN?, _ flags: UINT) -> BOOL
@_silgen_name("EnableWindow")
func EnableWindow(_ window: HWND?, _ enable: BOOL) -> BOOL
@_silgen_name("MoveWindow")
func MoveWindow(_ window: HWND?, _ x: Int32, _ y: Int32, _ width: Int32, _ height: Int32, _ repaint: BOOL) -> BOOL
@_silgen_name("GetClientRect")
func GetClientRect(_ window: HWND?, _ rect: UnsafeMutablePointer<RECT>) -> BOOL
@_silgen_name("SetWindowLongPtrW")
func SetWindowLongPtrW(_ window: HWND?, _ index: Int32, _ newValue: WNDPROC?) -> WNDPROC?
@_silgen_name("CallWindowProcW")
func CallWindowProcW(_ previous: WNDPROC?, _ window: HWND?, _ message: UINT, _ wParam: WPARAM, _ lParam: LPARAM) -> LRESULT
@_silgen_name("GetParent")
func GetParent(_ window: HWND?) -> HWND?
@_silgen_name("GetNextDlgTabItem")
func GetNextDlgTabItem(_ dialog: HWND?, _ control: HWND?, _ previous: BOOL) -> HWND?
@_silgen_name("SetFocus")
func SetFocus(_ window: HWND?) -> HWND?
@_silgen_name("GetKeyState")
func GetKeyState(_ virtualKey: Int32) -> Int16
@_silgen_name("TrackMouseEvent")
func TrackMouseEvent(_ eventTrack: UnsafeMutablePointer<TRACKMOUSEEVENT>) -> BOOL
@_silgen_name("SendMessageW")
func SendMessageW(_ window: HWND, _ message: UINT, _ wParam: WPARAM, _ lParam: LPARAM) -> LRESULT
@_silgen_name("CreateFontW")
func CreateFontW(_ height: Int32, _ width: Int32, _ escapement: Int32, _ orientation: Int32, _ weight: Int32, _ italic: DWORD, _ underline: DWORD, _ strikeOut: DWORD, _ charSet: DWORD, _ outputPrecision: DWORD, _ clipPrecision: DWORD, _ quality: DWORD, _ pitchAndFamily: DWORD, _ faceName: UnsafePointer<UInt16>) -> HFONT
@_silgen_name("CreateSolidBrush")
func CreateSolidBrush(_ color: DWORD) -> HBRUSH?
@_silgen_name("GetStockObject")
func GetStockObject(_ object: Int32) -> HGDIOBJ?
@_silgen_name("SetBkMode")
func SetBkMode(_ deviceContext: HDC?, _ backgroundMode: Int32) -> Int32
@_silgen_name("SetBkColor")
func SetBkColor(_ deviceContext: HDC?, _ color: DWORD) -> DWORD
@_silgen_name("SetTextColor")
func SetTextColor(_ deviceContext: HDC?, _ color: DWORD) -> DWORD
@_silgen_name("CreatePen")
func CreatePen(_ style: Int32, _ width: Int32, _ color: DWORD) -> HPEN?
@_silgen_name("SelectObject")
func SelectObject(_ deviceContext: HDC, _ object: HGDIOBJ?) -> HGDIOBJ?
@_silgen_name("DeleteObject")
func DeleteObject(_ object: HGDIOBJ?) -> BOOL
@_silgen_name("RoundRect")
func RoundRect(_ deviceContext: HDC, _ left: Int32, _ top: Int32, _ right: Int32, _ bottom: Int32, _ width: Int32, _ height: Int32) -> BOOL
@_silgen_name("Rectangle")
func Rectangle(_ deviceContext: HDC, _ left: Int32, _ top: Int32, _ right: Int32, _ bottom: Int32) -> BOOL
@_silgen_name("MoveToEx")
func MoveToEx(_ deviceContext: HDC, _ x: Int32, _ y: Int32, _ previousPoint: UnsafeMutablePointer<POINT>?) -> BOOL
@_silgen_name("LineTo")
func LineTo(_ deviceContext: HDC, _ x: Int32, _ y: Int32) -> BOOL
@_silgen_name("DrawTextW")
func DrawTextW(_ deviceContext: HDC, _ text: UnsafePointer<UInt16>, _ count: Int32, _ rect: UnsafeMutablePointer<RECT>, _ format: UINT) -> Int32
@_silgen_name("GetWindowTextLengthW")
func GetWindowTextLengthW(_ window: HWND) -> Int32
@_silgen_name("GetWindowTextW")
func GetWindowTextW(_ window: HWND, _ text: UnsafeMutablePointer<UInt16>?, _ maximumCount: Int32) -> Int32
@_silgen_name("SetWindowTextW")
func SetWindowTextW(_ window: HWND, _ text: UnsafePointer<UInt16>) -> BOOL
@_silgen_name("GetDlgCtrlID")
func GetDlgCtrlID(_ control: HWND) -> Int32
@_silgen_name("GetMessageW")
func GetMessageW(_ message: UnsafeMutablePointer<MSG>, _ window: HWND?, _ minimumMessage: UINT, _ maximumMessage: UINT) -> BOOL
@_silgen_name("IsDialogMessageW")
func IsDialogMessageW(_ window: HWND?, _ message: UnsafeMutablePointer<MSG>) -> BOOL
@_silgen_name("TranslateMessage")
func TranslateMessage(_ message: UnsafePointer<MSG>) -> BOOL
@_silgen_name("DispatchMessageW")
func DispatchMessageW(_ message: UnsafePointer<MSG>) -> LRESULT
@_silgen_name("DefWindowProcW")
func DefWindowProcW(_ window: HWND?, _ message: UINT, _ wParam: WPARAM, _ lParam: LPARAM) -> LRESULT
@_silgen_name("PostQuitMessage")
func PostQuitMessage(_ exitCode: Int32)
@_silgen_name("MessageBoxW")
func MessageBoxW(_ window: HWND?, _ text: UnsafePointer<UInt16>, _ caption: UnsafePointer<UInt16>, _ type: UINT) -> Int32
@_silgen_name("ShellExecuteW")
func ShellExecuteW(_ window: HWND?, _ operation: UnsafePointer<UInt16>?, _ file: UnsafePointer<UInt16>, _ parameters: UnsafePointer<UInt16>?, _ directory: UnsafePointer<UInt16>?, _ showCommand: Int32) -> HINSTANCE?
#endif
