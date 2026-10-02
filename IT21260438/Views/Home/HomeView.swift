//
//  HomeView.swift
//  IT21260438
//

import Combine
import CoreData
import SwiftUI

struct HomeView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.scenePhase) private var scenePhase

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DrinkRecord.date, ascending: false)],
        predicate: HomeView.predicate(forDayOf: .now),
        animation: .default
    )
    private var records: FetchedResults<DrinkRecord>

    @AppStorage(AppSettings.Key.dailyGoal) private var dailyGoal = AppSettings.defaultGoal
    @AppStorage(AppSettings.Key.cupSize) private var cupSize = AppSettings.defaultCup
    @AppStorage(AppSettings.Key.remindersEnabled) private var remindersEnabled = true
    @AppStorage(AppSettings.Key.wakeMinutes) private var wakeMinutes = AppSettings.defaultWake
    @AppStorage(AppSettings.Key.sleepMinutes) private var sleepMinutes = AppSettings.defaultSleep
    @AppStorage(AppSettings.Key.reminderInterval) private var reminderInterval = AppSettings.defaultInterval

    @State private var today = Calendar.current.startOfDay(for: .now)
    @State private var showCupPicker = false
    @State private var editorMode: RecordEditorView.Mode?

    private var intake: Int { records.reduce(0) { $0 + Int($1.amount) } }
    private var goalReached: Bool { dailyGoal > 0 && intake >= dailyGoal }

    private var message: String {
        let progress = dailyGoal > 0 ? Double(intake) / Double(dailyGoal) : 0
        let left = max(dailyGoal - intake, 0)
        switch progress {
        case 0: return "Start drinking first cup of water!"
        case 1...: return "Great job! You reached today's goal 🎉"
        case 0.75...: return "Almost there! Only \(left) ml to go."
        case 0.4...: return "Nice progress! Keep it flowing 💧"
        default: return "Good start! \(left) ml left for today."
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let gaugeSize = max(min(proxy.size.width - 56, 400), 200)

            ScrollView {
                VStack(spacing: 0) {
                    MascotHeader(message: message, cheering: goalReached)
                        .padding(.horizontal, 12)
                        .padding(.top, 16)

                    WaterGaugeView(
                        intake: intake,
                        goal: dailyGoal,
                        cupSize: cupSize,
                        size: gaugeSize,
                        onDrink: drink,
                        onSwitchCup: { showCupPicker = true }
                    )
                    .padding(.top, 20)

                    drinkHint
                        .padding(.top, -gaugeSize * 0.07)

                    recordsHeader
                        .padding(.top, 20)

                    recordsList
                        .padding(.top, 12)
                }
                .padding(.bottom, 32)
                .frame(width: proxy.size.width)
            }
        }
        .background(Color.white)
        .sensoryFeedback(.impact(weight: .medium), trigger: records.count)
        .sensoryFeedback(.success, trigger: goalReached) { old, new in !old && new }
        .sheet(isPresented: $showCupPicker) {
            CupPickerView(cupSize: $cupSize)
        }
        .sheet(item: $editorMode) { mode in
            RecordEditorView(mode: mode)
                .environment(\.managedObjectContext, context)
        }
        .onChange(of: today) {
            records.nsPredicate = HomeView.predicate(forDayOf: today)
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active { refreshDay() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in
            refreshDay()
        }
    }

    private var drinkHint: some View {
        VStack(spacing: 2) {
            Image(systemName: "arrowshape.up.fill")
                .font(.system(size: 13))
                .foregroundStyle(Theme.primary)
            Text("Confirm that you have just drunk water")
                .font(.system(size: 16))
                .foregroundStyle(.black)
        }
    }

    private var recordsHeader: some View {
        HStack(spacing: 14) {
            Text("Today's records")
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(.black)
            Button {
                editorMode = .add(.now)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.black)
            }
            .accessibilityLabel("Add record")
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    private var recordsList: some View {
        VStack(spacing: 12) {
            if remindersEnabled {
                TimelineView(.everyMinute) { timeline in
                    if let next = nextReminder(after: timeline.date) {
                        RecordRow(kind: .upcoming, time: next, amount: cupSize)
                    }
                }
            }

            ForEach(records) { record in
                RecordRow(
                    kind: .logged,
                    time: record.date ?? .now,
                    amount: Int(record.amount),
                    onEdit: { editorMode = .edit(record) },
                    onDelete: { delete(record) }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            if records.isEmpty && !remindersEnabled {
                Text("No water logged yet today.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: Actions

    private func drink() {
        refreshDay()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            RecordStore.add(amount: cupSize, goal: dailyGoal, in: context)
        }
    }

    private func delete(_ record: DrinkRecord) {
        withAnimation {
            RecordStore.delete(record, in: context)
        }
    }

    private func refreshDay() {
        let day = Calendar.current.startOfDay(for: .now)
        if day != today { today = day }
    }

    private func nextReminder(after now: Date) -> Date? {
        let times = NotificationManager.reminderTimes(wake: wakeMinutes, sleep: sleepMinutes, interval: reminderInterval).sorted()
        guard let first = times.first else { return nil }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        for minutes in times {
            if let date = calendar.date(byAdding: .minute, value: minutes, to: startOfDay), date > now {
                return date
            }
        }
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return nil }
        return calendar.date(byAdding: .minute, value: first, to: tomorrow)
    }

    static func predicate(forDayOf date: Date) -> NSPredicate {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
        return NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)
    }
}

struct RecordRow: View {
    enum Kind {
        case upcoming
        case logged
    }

    let kind: Kind
    let time: Date
    let amount: Int
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 18) {
            Group {
                switch kind {
                case .upcoming:
                    Image(systemName: "clock")
                        .font(.system(size: 24))
                        .foregroundStyle(.black)
                case .logged:
                    CupIcon(size: 30, showPlus: false)
                }
            }
            .frame(width: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(time.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 21))
                    .foregroundStyle(.black)
                if kind == .upcoming {
                    Text("Next time")
                        .font(.system(size: 17))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            Text("\(amount) ml")
                .font(.system(size: 19))
                .foregroundStyle(kind == .upcoming ? .secondary : .primary)

            if onEdit != nil || onDelete != nil {
                Menu {
                    if let onEdit {
                        Button(action: onEdit) { Label("Edit", systemImage: "pencil") }
                    }
                    if let onDelete {
                        Button(role: .destructive, action: onDelete) { Label("Delete", systemImage: "trash") }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 36)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Record options")
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.white)
                .shadow(color: .black.opacity(0.15), radius: 3, y: 1.5)
        )
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
