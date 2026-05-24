/// Calendar date value used by the traditional date picker.
///
/// Implementation note:
/// This intentionally avoids `Foundation.Date` for the first Windows slice.
/// The current ARM64 Windows Swift toolchain has shown overlay issues when
/// importing Foundation, while Win32 date picker controls naturally expose a
/// year/month/day `SYSTEMTIME` shape.
public struct WinDate: Equatable, Sendable {
    /// Four-digit calendar year.
    public var year: Int
    /// One-based month number.
    public var month: Int
    /// One-based day number.
    public var day: Int

    /// Creates a calendar date.
    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }
}

/// Date picker control in the traditional API.
///
/// The first implementation is date-only and maps to the Win32 Date Time
/// Picker common control. Time selection and richer calendar styles remain
/// planned compatibility work.
///
/// Windows note:
/// Keyboard entry is segmented by default in the native control. That is normal
/// Win32 behavior rather than a SwiftWin parser bug.
public final class WinDatePicker: WinDateControl, WinRefreshableControl {
    /// Label describing the selected date.
    public var title: String
    /// Current selected date.
    public var date: WinDate
    /// Closure invoked after native interaction changes the date.
    public var onChange: ((WinDate) -> Void)?
    /// Optional source of truth used when external state invalidates the view.
    public var dateProvider: (() -> WinDate)?

    /// Creates a date picker.
    public init(
        _ title: String,
        date: WinDate,
        onChange: ((WinDate) -> Void)? = nil,
        dateProvider: (() -> WinDate)? = nil
    ) {
        self.title = title
        self.date = date
        self.onChange = onChange
        self.dateProvider = dateProvider
    }

    /// Mirrors the current Swift value into the active native control.
    public func refresh() {
        WinControlInvalidation.refresh(self)
    }
}
