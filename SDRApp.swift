import SwiftUI

@main
struct SDRApp: App {
    var body: some Scene {
        WindowGroup {
            SDRView()
                .frame(minWidth: 400, minHeight: 300)
        }
        .windowStyle(.hiddenTitleBar)
    }
} 