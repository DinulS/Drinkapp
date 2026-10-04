//
//  IT21260438TVApp.swift
//  IT21260438TV
//
//  Apple TV version of the Water Reminder app. Models, persistence, charts and drawings are shared
//  with the iOS target; everything in this folder is the tvOS-specific, focus-driven UI.
//

import CoreData
import SwiftUI

@main
struct IT21260438TVApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        AppSettings.registerDefaults()
    }

    var body: some Scene {
        WindowGroup {
            TVContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(.light)
        }
    }
}
