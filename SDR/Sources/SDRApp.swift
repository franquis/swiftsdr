//
//  SDRApp.swift
//  SDR
//
//  Created by François Perret du Cray on 05/04/2025.
//

import SwiftUI

@main
@available(macOS 13.0, *)
struct SDRApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
