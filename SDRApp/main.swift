import SwiftUI
import SDR

@main
@available(macOS 12.0, *)
struct SDRApp: App {
    var body: some Scene {
        WindowGroup {
            SDRView()
        }
    }
} 