/// Calendar date value used by SwiftWinUI's first date picker slice.
///
/// Compatibility note:
/// SwiftUI uses `Foundation.Date`. SwiftWinUI starts with this date-only value
/// so the Windows prototype can avoid Foundation overlay problems in the local
/// ARM64 toolchain. A `Date` overload remains planned.
public struct CalendarDate: Equatable, Sendable {
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

/// Date picker in the declarative SwiftWinUI layer.
public struct DatePicker: View {
    private let title: String
    private let date: CalendarDate
    private let dateProvider: (() -> CalendarDate)?
    private let onChange: ((CalendarDate) -> Void)?

    /// Creates a date picker with a fixed initial date.
    public init(
        _ title: String,
        date: CalendarDate,
        onChange: ((CalendarDate) -> Void)? = nil
    ) {
        self.title = title
        self.date = date
        self.dateProvider = nil
        self.onChange = onChange
    }

    /// Creates a date picker bound to mutable state.
    public init(_ title: String, selection: Binding<CalendarDate>) {
        self.title = title
        self.date = selection.wrappedValue
        self.dateProvider = { selection.wrappedValue }
        self.onChange = { value in
            selection.wrappedValue = value
        }
    }

    /// Emits a date-picker operation to the renderer.
    public func render(into context: RenderContext) {
        context.renderer.datePicker(title, date: date, dateProvider: dateProvider, onChange: onChange)
    }
}
