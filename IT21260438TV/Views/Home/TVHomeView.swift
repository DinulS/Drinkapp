//
//  TVHomeView.swift
//  IT21260438TV
//

import Combine
import CoreData
import SwiftUI

/// Two-column home screen: the mascot and drink gauge on the left, today's records on the right.
struct TVHomeView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Environment(TVReminderCenter.self) private var reminders

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DrinkRecord.date, ascending: false)],
        predicate: TVHomeView.predicate(forDayOf: .now),
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
    @State private var editorMode: TVRecordEditorView.Mode?
    @State private var selectedRecord: DrinkRecord?
    @FocusState private var drinkFocused: Bool

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

    private var reminderTimes: [Int] {
        TVReminderCenter.reminderTimes(wake: wakeMinutes, sleep: sleepMinutes, interval: reminderInterval)
    }

    var body: some View {
        GeometryReader { proxy in
            // Leave room for the mascot header and the controls row under the gauge.
            let gaugeSize = min(max(proxy.size.height - 330, 300), 560)

            HStack(alignment: .top, spacing: 80) {
                drinkColumn(gaugeSize: gaugeSize)
                    .frame(width: proxy.size.width * 0.5)
                recordsColumn
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .defaultFocus($drinkFocused, true)
        .sheet(isPresented: $showCupPicker) {
            TVCupPickerView(cupSize: $cupSize)
        }
        .sheet(item: $editorMode) { mode in
            TVRecordEditorView(mode: mode)
                .environment(\.managedObjectContext, context)
        }
        .confirmationDialog(
            selectedRecord.map { "\($0.amount) ml at \(($0.date ?? .now).formatted(date: .omitted, time: .shortened))" } ?? "",
            isPresented: Binding(
                get: { selectedRecord != nil },
                set: { if !$0 { selectedRecord = nil } }
            ),
            titleVisibility: .visible,
            presenting: selectedRecord
        ) { record in
            Button("Edit") { editorMode = .edit(record) }
            Button("Delete", role: .destructive) { delete(record) }
            Button("Cancel", role: .cancel) {}
        }
        .onChange(of: today) {
            records.nsPredicate = TVHomeView.predicate(forDayOf: today)
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active { refreshDay() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in
            refreshDay()
        }
    }

    // MARK: Columns

    private func drinkColumn(gaugeSize: CGFloat) -> some View {
        VStack(spacing: 28) {
            TVMascotHeader(message: message, cheering: goalReached)

            Button(action: drink) {
                TVWaterGauge(intake: intake, goal: dailyGoal, cupSize: cupSize, size: gaugeSize)
            }
            .buttonStyle(TVLiftButtonStyle())
            .focused($drinkFocused)
            .accessibilityLabel("Drink \(cupSize) millilitres")

            HStack(spacing: 40) {
                HStack(spacing: 12) {
                    Image(systemName: "arrowshape.up.fill")
                        .foregroundStyle(Theme.primary)
                    Text("Click to confirm you've just drunk water")
                        .foregroundStyle(.black)
                }
                .font(.callout)

                Button {
                    showCupPicker = true
                } label: {
                    Label("Switch cup", systemImage: "arrow.triangle.2.circlepath")
                }
            }
        }
    }

    private var recordsColumn: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Today's records")
                    .font(.title2.bold())
                    .foregroundStyle(.black)
                Spacer()
                Button {
                    editorMode = .add(.now)
                } label: {
                    Label("Add record", systemImage: "plus")
                }
            }

            ScrollView {
                LazyVStack(spacing: 24) {
                    if remindersEnabled {
                        TimelineView(.everyMinute) { timeline in
                            if let next = TVReminderCenter.nextReminder(after: timeline.date, times: reminderTimes) {
                                TVRecordRow(kind: .upcoming, time: next, amount: cupSize)
                                    .background(RoundedRectangle(cornerRadius: 16).fill(Theme.card))
                            }
                        }
                    }

                    ForEach(records) { record in
                        Button {
                            selectedRecord = record
                        } label: {
                            TVRecordRow(kind: .logged, time: record.date ?? .now, amount: Int(record.amount))
                        }
                        .buttonStyle(.card)
                        .accessibilityHint("Shows options to edit or delete this record")
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if records.isEmpty {
                        Text("No water logged yet today.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                    }
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
            }
            // Keep the lifted, focused card from being clipped by the scroll view.
            .scrollClipDisabled()
        }
    }

    // MARK: Actions

    private func drink() {
        refreshDay()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            RecordStore.add(amount: cupSize, goal: dailyGoal, in: context)
        }
        reminders.clearBadge()
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

    static func predicate(forDayOf date: Date) -> NSPredicate {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
        return NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)
    }
}

/// The mascot with its speech bubble, scaled up for the TV.
struct TVMascotHeader: View {
    let message: String
    var cheering = false

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            MascotView(cheering: cheering)
                .scaleEffect(1.5)
                .frame(width: 150, height: 180)
            Text(message)
                .font(.title3)
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .padding(.leading, 18 + 24)
                .padding(.trailing, 24)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity, minHeight: 130)
                .background(SpeechBubbleShape(tailSize: 18, cornerRadius: 28).fill(Theme.bubble))
                .contentTransition(.opacity)
                .animation(.easeInOut, value: message)
        }
    }
}

struct TVRecordRow: View {
    enum Kind {
        case upcoming
        case logged
    }

    let kind: Kind
    let time: Date
    let amount: Int

    var body: some View {
        HStack(spacing: 28) {
            Group {
                switch kind {
                case .upcoming:
                    Image(systemName: "clock")
                        .font(.title2)
                        .foregroundStyle(.black)
                case .logged:
                    CupIcon(size: 48, showPlus: false)
                }
            }
            .frame(width: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(time.formatted(date: .omitted, time: .shortened))
                    .font(.title3)
                    .foregroundStyle(.black)
                if kind == .upcoming {
                    Text("Next reminder")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 12)

            Text("\(amount) ml")
                .font(.title3)
                .foregroundStyle(kind == .upcoming ? .secondary : .primary)

            if kind == .logged {
                Image(systemName: "ellipsis")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    TVHomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environment(TVReminderCenter.shared)
}
