import SwiftWinLegacy

/// Keyboard modifier flags for SwiftUI-compatible shortcuts.
///
/// `command` intentionally maps to Control in the current Windows backend so
/// Mac-oriented app code has a reasonable first-pass behavior on PC keyboards.
public struct EventModifiers: OptionSet, Sendable, Hashable {
    /// Raw bit storage.
    public let rawValue: Int

    /// Creates a modifier set from raw bits.
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Control key modifier.
    public static let control = EventModifiers(rawValue: 1 << 0)
    /// Shift key modifier.
    public static let shift = EventModifiers(rawValue: 1 << 1)
    /// Alt/Option key modifier.
    public static let option = EventModifiers(rawValue: 1 << 2)
    /// Apple-style Command modifier, mapped to Control on Windows.
    public static let command = EventModifiers(rawValue: 1 << 3)
}

/// SwiftUI-compatible keyboard shortcut metadata.
public struct KeyboardShortcut: Sendable, Hashable {
    /// Single-character shortcut key.
    public var key: String
    /// Required modifier keys.
    public var modifiers: EventModifiers

    /// Creates a shortcut descriptor.
    public init(_ key: String, modifiers: EventModifiers = .command) {
        self.key = key
        self.modifiers = modifiers
    }
}

/// View wrapper that applies a keyboard shortcut scope.
public struct KeyboardShortcutModifier<Content: View>: View {
    private let content: Content
    private let shortcut: KeyboardShortcut

    /// Creates a shortcut wrapper.
    public init(content: Content, shortcut: KeyboardShortcut) {
        self.content = content
        self.shortcut = shortcut
    }

    /// Emits shortcut scope around the wrapped content.
    public func render(into context: RenderContext) {
        context.renderer.beginKeyboardShortcut(shortcut)
        content.render(into: context)
        context.renderer.endKeyboardShortcut()
    }
}

public extension View {
    /// Applies a keyboard shortcut to command controls inside this view.
    func keyboardShortcut(_ key: String, modifiers: EventModifiers = .command) -> KeyboardShortcutModifier<Self> {
        KeyboardShortcutModifier(content: self, shortcut: KeyboardShortcut(key, modifiers: modifiers))
    }
}

extension EventModifiers {
    /// Maps SwiftUI-compatible modifiers into the traditional backend.
    var winKeyboardModifiers: WinKeyboardModifiers {
        var result: WinKeyboardModifiers = []
        if contains(.control) { result.insert(.control) }
        if contains(.shift) { result.insert(.shift) }
        if contains(.option) { result.insert(.option) }
        if contains(.command) { result.insert(.command) }
        return result
    }
}

extension KeyboardShortcut {
    /// Maps a declarative shortcut into the traditional backend.
    var winKeyboardShortcutDescriptor: WinKeyboardShortcutDescriptor {
        WinKeyboardShortcutDescriptor(key, modifiers: modifiers.winKeyboardModifiers)
    }
}
