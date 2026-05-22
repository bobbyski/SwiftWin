import SwiftWinUI

struct DemoApp: App {
    var body: some Scene {
        WindowGroup("SwiftWinUI Demo") {
            VStack(spacing: 12) {
                Text("SwiftWinUI", style: .title)
                Text("A Swift-first framework for Windows desktop interfaces.")
                HStack {
                    Button("Create Window") {
                        print("Create Window tapped")
                    }
                    Button("Settings") {
                        print("Settings tapped")
                    }
                }
                Spacer()
                Text("Renderer boundary is ready for Win32 or WinUI.", style: .caption)
            }
        }
    }
}

DemoApp.main()
