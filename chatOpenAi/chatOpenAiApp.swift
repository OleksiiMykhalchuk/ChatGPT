//
//  chatOpenAiApp.swift
//  chatOpenAi
//
//  Created by Oleksii Mykhalchuk on 2/12/24.
//

import SwiftUI
import SwiftData
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private let logger: AppLogger = AppLogger()

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("Application has launched")
    }
}

@main
struct chatOpenAiApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if NSClassFromString("XCTestCase") != nil {
                EmptyView()
            } else {
                MainView()
            }

        }
        .modelContainer(sharedModelContainer)

    }
}
