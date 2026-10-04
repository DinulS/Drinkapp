//
//  Persistence.swift
//  IT21260438
//
//  Created by Janith Kavinda on 2026-09-27.
//

import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()

    /// In-memory store filled with three weeks of sample data, used by SwiftUI previews.
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let context = result.container.viewContext
        let calendar = Calendar.current
        for dayOffset in 0..<21 {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: .now) else { continue }
            let cups = dayOffset == 0 ? 3 : Int.random(in: 4...12)
            for cup in 0..<cups {
                let date = calendar.date(bySettingHour: 7 + cup, minute: 30, second: 0, of: day) ?? day
                DrinkRecord.insert(into: context, amount: 200, date: date, goal: AppSettings.defaultGoal)
            }
        }
        RecordStore.save(context)
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let container = NSPersistentContainer(name: "IT21260438")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        #if os(tvOS)
        // tvOS apps have no persistent local storage; the caches directory is the only writable place for the store.
        if !inMemory, let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            container.persistentStoreDescriptions.first?.url = caches.appendingPathComponent("IT21260438.sqlite")
        }
        #endif
        container.loadPersistentStores { _, error in
            if let error {
                print("Core Data failed to load the store: \(error)")
            }
        }
        // The store can be incompatible after a model change during development: rebuild it.
        if container.persistentStoreCoordinator.persistentStores.isEmpty,
           !inMemory,
           let url = container.persistentStoreDescriptions.first?.url {
            try? container.persistentStoreCoordinator.destroyPersistentStore(at: url, ofType: NSSQLiteStoreType, options: nil)
            container.loadPersistentStores { _, error in
                if let error {
                    fatalError("Unresolved Core Data error: \(error)")
                }
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        self.container = container
    }
}
