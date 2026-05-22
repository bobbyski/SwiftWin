#if os(Windows)
public final class Win32Renderer: Renderer {
    public init() {}

    public func beginWindow(_ descriptor: WindowDescriptor) {
        // The native backend will translate this node into an HWND once WinSDK
        // imports cleanly in the target toolchain.
    }

    public func endWindow() {}

    public func beginStack(axis: StackAxis, spacing: Double) {}

    public func endStack() {}

    public func text(_ value: String, style: TextStyle) {}

    public func button(_ title: String, action: @escaping () -> Void) {}

    public func spacer() {}
}
#endif
