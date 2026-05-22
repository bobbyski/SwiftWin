import SwiftWinUI

struct DemoApp: App {
    var body: some Scene {
        WindowGroup("SwiftWinUI Demo") {
            VStack(spacing: 14) {
                Text("SwiftWinUI", style: .title)
                Text("A Swift-first framework for Windows desktop apps that can finally open real windows.")
                HStack(spacing: 10) {
                    Button("Create Window", style: .primary) {
                        Dialog.show(
                            title: "Create Window",
                            message: "Button actions are wired through Win32 command routing."
                        )
                    }
                    Button("Settings") {
                        Dialog.show(
                            title: "Settings",
                            message: "Next stop: real settings controls, state, and a layout engine with taste."
                        )
                    }
                }
                Spacer()
                Text("Native Win32 backend: active. Console renderer: still available for diagnostics.", style: .caption)
            }
        }
    }
}

DemoApp.main()
