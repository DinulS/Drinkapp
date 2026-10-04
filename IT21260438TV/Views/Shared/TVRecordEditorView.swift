//
//  TVRecordEditorView.swift
//  IT21260438TV
//

import CoreData
import SwiftUI

/// Full-screen sheet for adding a drink record at any recent time, or editing / deleting an existing one.
/// tvOS has no `DatePicker` or `Stepper`, so day, time and amount are set with − / + adjusters.
struct TVRecordEditorView: View {
    enum Mode: Identifiable {
        case add(Date)
        case edit(DrinkRecord)

        var id: String {
            switch self {
            case .add: "add"
            case .edit(let record): record.objectID.uriRepresentation().absoluteString
            }
        }
    }

    /// How far back a record can be added.
    private static let maxDaysBack = 30

    let mode: Mode

    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppSettings.Key.dailyGoal) private var dailyGoal = AppSettings.defaultGoal

    /// Start of the record's day.
    @State private var day: Date
    /// Time of day, in minutes after midnight.
    @State private var minutes: Int
    @State private var amount: Int
    @State private var showDeleteConfirm = false
    @FocusState private var saveFocused: Bool

    private let calendar = Calendar.current

    init(mode: Mode) {
        self.mode = mode
        let date: Date
        switch mode {
        case .add(let initial):
            let cup = UserDefaults.standard.integer(forKey: AppSettings.Key.cupSize)
            date = min(initial, .now)
            _amount = State(initialValue: cup > 0 ? cup : AppSettings.defaultCup)
        case .edit(let record):
            date = record.date ?? .now
            _amount = State(initialValue: Int(record.amount))
        }
        _day = State(initialValue: Calendar.current.startOfDay(for: date))
        _minutes = State(initialValue: AppSettings.minutes(from: date))
    }

    private var editedRecord: DrinkRecord? {
        if case .edit(let record) = mode { return record }
        return nil
    }

    private var date: Date { AppSettings.date(fromMinutes: minutes, on: day) }
    private var isInFuture: Bool { date > .now }

    private var dayLabel: String {
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    var body: some View {
        VStack(spacing: 56) {
            VStack(spacing: 12) {
                Text(editedRecord == nil ? "Add record" : "Edit record")
                    .font(.title.bold())
                    .foregroundStyle(.black)
                Text("\(amount) ml on \(date.formatted(date: .complete, time: .shortened))")
                    .font(.headline)
                    .foregroundStyle(isInFuture ? Color.red : Theme.primary)
                if isInFuture {
                    Text("Pick a time that isn't in the future.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(alignment: .top, spacing: 70) {
                TVAdjuster(title: "Day", value: dayLabel, valueWidth: 300, onDecrease: { shiftDay(by: -1) }, onIncrease: { shiftDay(by: 1) })
                TVAdjuster(title: "Hour", value: date.formatted(.dateTime.hour()), valueWidth: 160, onDecrease: { shiftHour(by: -1) }, onIncrease: { shiftHour(by: 1) })
                TVAdjuster(title: "Minute", value: String(format: "%02d", minutes % 60), valueWidth: 120, onDecrease: { shiftMinute(by: -5) }, onIncrease: { shiftMinute(by: 5) })
            }

            VStack(spacing: 28) {
                TVAdjuster(
                    title: "Amount",
                    value: "\(amount) ml",
                    onDecrease: { amount = max(amount - 10, AppSettings.cupRange.lowerBound) },
                    onIncrease: { amount = min(amount + 10, AppSettings.cupRange.upperBound) }
                )
                HStack(spacing: 20) {
                    ForEach(AppSettings.cupSizes, id: \.self) { size in
                        Button("\(size) ml") { amount = size }
                            .tint(amount == size ? Theme.primary : nil)
                            .accessibilityAddTraits(amount == size ? .isSelected : [])
                    }
                }
                .font(.callout)
            }

            HStack(spacing: 40) {
                Button("Save", action: save)
                    .disabled(isInFuture)
                    .focused($saveFocused)
                Button("Cancel", role: .cancel) { dismiss() }
                if editedRecord != nil {
                    Button("Delete record", role: .destructive) { showDeleteConfirm = true }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.ignoresSafeArea())
        .defaultFocus($saveFocused, true)
        .confirmationDialog("Delete this record?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive, action: delete)
        }
    }

    // MARK: Adjusting

    private func shiftDay(by value: Int) {
        let today = calendar.startOfDay(for: .now)
        let earliest = calendar.date(byAdding: .day, value: -Self.maxDaysBack, to: today) ?? today
        guard let shifted = calendar.date(byAdding: .day, value: value, to: day) else { return }
        day = min(max(shifted, earliest), today)
    }

    /// Moves the hour, wrapping around midnight without changing the day.
    private func shiftHour(by value: Int) {
        let minutesPerDay = 24 * 60
        minutes = (minutes + value * 60 + minutesPerDay) % minutesPerDay
    }

    /// Moves the minute, wrapping within the hour.
    private func shiftMinute(by value: Int) {
        let minute = (minutes % 60 + value + 60) % 60
        minutes = minutes / 60 * 60 + minute
    }

    // MARK: Saving

    private func save() {
        guard !isInFuture else { return }
        withAnimation {
            if let record = editedRecord {
                RecordStore.update(record, amount: amount, date: date, in: context)
            } else {
                RecordStore.add(amount: amount, date: date, goal: dailyGoal, in: context)
            }
        }
        dismiss()
    }

    private func delete() {
        guard let record = editedRecord else { return }
        withAnimation {
            RecordStore.delete(record, in: context)
        }
        dismiss()
    }
}

#Preview {
    TVRecordEditorView(mode: .add(.now))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
