//
//  RecordEditorView.swift
//  IT21260438
//

import CoreData
import SwiftUI

/// Sheet for adding a drink record at any past time, or editing / deleting an existing one.
struct RecordEditorView: View {
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

    let mode: Mode

    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppSettings.Key.dailyGoal) private var dailyGoal = AppSettings.defaultGoal

    @State private var date: Date
    @State private var amount: Int
    @State private var showDeleteConfirm = false

    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .add(let date):
            let cup = UserDefaults.standard.integer(forKey: AppSettings.Key.cupSize)
            _date = State(initialValue: min(date, .now))
            _amount = State(initialValue: cup > 0 ? cup : AppSettings.defaultCup)
        case .edit(let record):
            _date = State(initialValue: record.date ?? .now)
            _amount = State(initialValue: Int(record.amount))
        }
    }

    private var editedRecord: DrinkRecord? {
        if case .edit(let record) = mode { return record }
        return nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("When") {
                    DatePicker("Date & time", selection: $date, in: ...Date.now, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Amount") {
                    Stepper(value: $amount, in: AppSettings.cupRange, step: 10) {
                        HStack {
                            Text("Amount")
                            Spacer()
                            Text("\(amount) ml")
                                .monospacedDigit()
                                .foregroundStyle(Theme.primary)
                        }
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(AppSettings.cupSizes, id: \.self) { size in
                                Button("\(size) ml") { amount = size }
                                    .buttonStyle(.bordered)
                                    .tint(amount == size ? Theme.primary : .gray)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                if editedRecord != nil {
                    Section {
                        Button("Delete record", role: .destructive) { showDeleteConfirm = true }
                    }
                }
            }
            .navigationTitle(editedRecord == nil ? "Add record" : "Edit record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                }
            }
            .confirmationDialog("Delete this record?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive, action: delete)
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func save() {
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
