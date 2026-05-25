/// Keyboard modifier flags understood by SwiftWinLegacy shortcuts.
///
/// Design note:
/// `command` is included for Apple-developer ergonomics. The Win32 backend maps
/// it to Control for now because Windows keyboards do not have a direct Command
/// key equivalent in normal desktop app shortcuts.
public struct WinKeyboardModifiers: OptionSet, Sendable, Hashable {
    /// Raw bit storage.
    public let rawValue: Int

    /// Creates a modifier set from raw bits.
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Control key modifier.
    public static let control = WinKeyboardModifiers(rawValue: 1 << 0)
    /// Shift key modifier.
    public static let shift = WinKeyboardModifiers(rawValue: 1 << 1)
    /// Alt/Option key modifier.
    public static let option = WinKeyboardModifiers(rawValue: 1 << 2)
    /// Apple-style Command modifier, mapped to Control on Windows.
    public static let command = WinKeyboardModifiers(rawValue: 1 << 3)
}

/// Keyboard shortcut metadata applied to command controls in a scope.
public struct WinKeyboardShortcutDescriptor: Sendable, Hashable {
    /// Single-character shortcut key.
    public var key: String
    /// Required modifier keys.
    public var modifiers: WinKeyboardModifiers

    /// Creates a shortcut descriptor.
    public init(_ key: String, modifiers: WinKeyboardModifiers = .command) {
        self.key = key
        self.modifiers = modifiers
    }
}

/// Container that applies a keyboard shortcut to child command controls.
public final class WinKeyboardShortcut: WinContainer {
    /// Shortcut metadata applied to child command controls.
    public var shortcut: WinKeyboardShortcutDescriptor
    /// Child elements in this shortcut scope.
    public private(set) var children: [WinElement] = []

    /// Creates a keyboard shortcut scope.
    public init(_ key: String, modifiers: WinKeyboardModifiers = .command) {
        self.shortcut = WinKeyboardShortcutDescriptor(key, modifiers: modifiers)
    }

    /// Appends a child element.
    public func add(_ element: WinElement) {
        children.append(element)
    }
}
