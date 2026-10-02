//
//  DrinkRecord+Helpers.swift
//  IT21260438
//

import CoreData
import Foundation

extension DrinkRecord {
    @discardableResult
    static func insert(into context: NSManagedObjectContext, amount: Int, date: Date, goal: Int) -> DrinkRecord {
        let record = DrinkRecord(context: context)
        record.uuid = UUID()
        record.date = date
        record.amount = Int32(amount)
        record.goal = Int32(goal)
        return record
    }
}

/// Small set of write operations on drink records, shared by the UI and the notification action.
enum RecordStore {
    static func add(amount: Int, date: Date = .now, goal: Int, in context: NSManagedObjectContext) {
        DrinkRecord.insert(into: context, amount: amount, date: date, goal: goal)
        save(context)
    }

    static func update(_ record: DrinkRecord, amount: Int, date: Date, in context: NSManagedObjectContext) {
        record.amount = Int32(amount)
        record.date = date
        save(context)
    }

    static func delete(_ record: DrinkRecord, in context: NSManagedObjectContext) {
        context.delete(record)
        save(context)
    }

    static func deleteAll(in context: NSManagedObjectContext) {
        let request: NSFetchRequest<DrinkRecord> = DrinkRecord.fetchRequest()
        let records = (try? context.fetch(request)) ?? []
        for record in records {
            context.delete(record)
        }
        save(context)
    }

    static func save(_ context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            context.rollback()
            print("Failed to save drink records: \(error)")
        }
    }
}
