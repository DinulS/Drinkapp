//
//  IT21260438App.swift
//  IT21260438
//
//  Created by Janith Kavinda on 2026-09-27.
//

import CoreData
import SwiftUI
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        AppSettings.registerDefaults()
        // Set the notification delegate before launch finishes so reminder actions are handled on cold start.
        NotificationManager.shared.configure()
        return true
    }
}

@main
struct IT21260438App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(.light)
        }
    }
}
