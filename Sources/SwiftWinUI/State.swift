/// A two-way value connection between declarative controls and mutable state.
///
/// `Binding` mirrors SwiftUI's core idea: controls read their current value
/// through `wrappedValue` and write user edits back through the same property.
/// The implementation is closure-backed so it can point at `State` today and
/// other storage sources in the future.
public struct Binding<Value> {
    private let getValue: () -> Value
    private let setValue: (Value) -> Void

    /// Reads or writes the connected value.
    public var wrappedValue: Value {
        get {
            getValue()
        }
        nonmutating set {
            setValue(newValue)
        }
    }

    /// Creates a binding from explicit get and set closures.
    public init(
        get: @escaping () -> Value,
        set: @escaping (Value) -> Void
    ) {
        self.getValue = get
        self.setValue = set
    }

    /// Creates a binding to constant read-only data.
    ///
    /// Implementation note:
    /// Writes are intentionally ignored, matching SwiftUI's `Binding.constant`
    /// behavior closely enough for previews, diagnostics, and disabled inputs.
    public static func constant(_ value: Value) -> Binding<Value> {
        Binding(
            get: { value },
            set: { _ in }
        )
    }
}

/// Local mutable view state for the declarative SwiftWinUI layer.
///
/// This is the first compatibility step toward SwiftUI's `@State`. It stores
/// the value in a reference box so nonmutating writes from event callbacks can
/// update state even though views are value types.
@propertyWrapper
public struct State<Value> {
    private let storage: StateStorage<Value>

    /// Reads or writes the current state value.
    public var wrappedValue: Value {
        get {
            storage.value
        }
        nonmutating set {
            storage.value = newValue
        }
    }

    /// Exposes this state as a two-way `Binding`.
    public var projectedValue: Binding<Value> {
        Binding(
            get: { storage.value },
            set: { storage.value = $0 }
        )
    }

    /// Creates state with an initial wrapped value.
    public init(wrappedValue: Value) {
        self.storage = StateStorage(wrappedValue)
    }
}

/// Reference storage used by `State`.
///
/// Keeping this class private preserves the public value-type surface while
/// allowing closures stored by native controls to mutate the underlying value.
private final class StateStorage<Value> {
    var value: Value

    init(_ value: Value) {
        self.value = value
    }
}
