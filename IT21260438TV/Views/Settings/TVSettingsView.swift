//
//  TVSettingsView.swift
//  IT21260438TV
//

import CoreData
import SwiftUI
import UserNotifications

/// Settings laid out like the tvOS Settings app: a summary on the left, a list on the right.
/// Values are chosen from lists because tvOS has no `Stepper` or `DatePicker`.
struct TVSettingsView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Environment(TVReminderCenter.self) private var reminders

    @AppStorage(AppSettings.Key.remindersEnabled) private var remindersEnabled = true
    @AppStorage(AppSettings.Key.reminderInterval) private var reminderInterval = AppSettings.defaultInterval
    @AppStorage(AppSettings.Key.wakeMinutes) private var wakeMinutes = AppSettings.defaultWake
    @AppStorage(AppSettings.Key.sleepMinutes) private var sleepMinutes = AppSettings.defaultSleep
    @AppStorage(AppSettings.Key.dailyGoal) private var dailyGoal = AppSettings.defaultGoal
    @AppStorage(AppSettings.Key.autoGoal) private var autoGoal = true
    @AppStorage(AppSettings.Key.weight) private var weight = AppSettings.defaultWeight
    @AppStorage(AppSettings.Key.gender) private var gender = AppSettings.defaultGender
    @AppStorage(AppSettings.Key.cupSize) private var cupSize = AppSettings.defaultCup

    @State private var authorization: UNAuthorizationStatus = .notDetermined
    @State private var showClearConfirm = false

    private static let timeSteps = Array(stride(from: 0, to: 24 * 60, by: 15))
    private static let weights = Array(20...200)
    private static let goals = Array(stride(from: AppSettings.goalRange.lowerBound, through: AppSettings.goalRange.upperBound, by: 50))

    private var reminderTimes: [Int] {
        TVReminderCenter.reminderTimes(wake: wakeMinutes, sleep: sleepMinutes, interval: reminderInterval)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            HStack(alignment: .top, spacing: 80) {
                summaryPanel
                    .frame(width: 560)

                Form {
                    reminderSection
                    goalSection

                    Section("Cup") {
                        Picker("Default cup size", selection: $cupSize) {
                            ForEach(Self.options(AppSettings.cupSizes, including: cupSize), id: \.self) { size in
                                Text("\(size) ml").tag(size)
                            }
                        }
                    }

                    Section {
                        Button("Clear all records", role: .destructive) { showClearConfirm = true }
                    } header: {
                        Text("Data")
                    } footer: {
                        Text("Records are stored only on this Apple TV. tvOS may remove them if it runs low on storage.")
                    }
                }
                .pickerStyle(.navigationLink)
            }
            .background(Color.white.ignoresSafeArea())
        }
        .confirmationDialog("Delete all drink records?", isPresented: $showClearConfirm, titleVisibility: .visible) {
            Button("Delete all", role: .destructive) {
                withAnimation { RecordStore.deleteAll(in: context) }
            }
        } message: {
            Text("This removes your whole history and cannot be undone.")
        }
        .task { await refreshAuthorization() }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                Task { await refreshAuthorization() }
            }
        }
        .onChange(of: remindersEnabled) { reschedule() }
        .onChange(of: reminderInterval) { reschedule() }
        .onChange(of: wakeMinutes) { reschedule() }
        .onChange(of: sleepMinutes) { reschedule() }
        .onChange(of: weight) { recalculateGoal() }
        .onChange(of: gender) { recalculateGoal() }
        .onChange(of: autoGoal) { recalculateGoal() }
    }

    // MARK: Sections

    private var summaryPanel: some View {
        VStack(spacing: 28) {
            MascotView()
                .scaleEffect(2.4)
                .frame(width: 240, height: 288)
            Text("Water Reminder")
                .font(.title2.bold())
                .foregroundStyle(.black)
            Text("Daily drink target: \(dailyGoal) ml")
                .font(.headline)
                .foregroundStyle(Theme.primary)
            Text("Version \(appVersion)")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxHeight: .infinity)
    }

    private var reminderSection: some View {
        Section {
            Toggle(isOn: $remindersEnabled) {
                Label("Drink reminders", systemImage: "bell.fill")
            }

            if remindersEnabled {
                Picker("Wake-up time", selection: $wakeMinutes) {
                    timeOptions(including: wakeMinutes)
                }
                Picker("Bedtime", selection: $sleepMinutes) {
                    timeOptions(including: sleepMinutes)
                }
                Picker("Remind every", selection: $reminderInterval) {
                    ForEach(AppSettings.intervals, id: \.self) { minutes in
                        Text(AppSettings.intervalLabel(minutes)).tag(minutes)
                    }
                }
                LabeledContent("Reminders per day", value: "\(reminderTimes.count)")
                Button("Preview a reminder") { reminders.presentReminder() }
            }
        } header: {
            Text("Reminders")
        } footer: {
            if authorization == .denied {
                Text("App icon badges are turned off in Settings. Reminders still pop up while Water Reminder is open.")
            } else {
                Text("Reminders pop up while Water Reminder is open, and a badge marks its icon when it isn't.")
            }
        }
    }

    private var goalSection: some View {
        Section {
            Toggle("Calculate from body weight", isOn: $autoGoal)

            if autoGoal {
                Picker("Gender", selection: $gender) {
                    ForEach(Gender.allCases) { gender in
                        Text(gender.title).tag(gender)
                    }
                }
                Picker("Weight", selection: $weight) {
                    ForEach(Self.options(Self.weights, including: weight), id: \.self) { kg in
                        Text("\(kg) kg").tag(kg)
                    }
                }
            } else {
                Picker("Target", selection: $dailyGoal) {
                    ForEach(Self.options(Self.goals, including: dailyGoal), id: \.self) { ml in
                        Text("\(ml) ml").tag(ml)
                    }
                }
            }

            LabeledContent("Daily drink target") {
                Text("\(dailyGoal) ml")
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.primary)
            }
        } header: {
            Text("Daily drink target")
        } footer: {
            if autoGoal {
                Text("Based on about \(gender == .male ? 35 : 31) ml of water per kg of body weight.")
            }
        }
    }

    // MARK: Helpers

    private func timeOptions(including current: Int) -> some View {
        ForEach(Self.options(Self.timeSteps, including: current), id: \.self) { minutes in
            Text(AppSettings.date(fromMinutes: minutes).formatted(date: .omitted, time: .shortened)).tag(minutes)
        }
    }

    /// The preset values plus the current one, so a value set elsewhere still shows as selected.
    private static func options(_ values: [Int], including current: Int) -> [Int] {
        Array(Set(values + [current])).sorted()
    }

    private func refreshAuthorization() async {
        authorization = await reminders.authorizationStatus()
    }

    private func reschedule() {
        reminders.rescheduleReminders()
    }

    private func recalculateGoal() {
        guard autoGoal else { return }
        dailyGoal = AppSettings.recommendedGoal(weight: weight, gender: gender)
    }
}

#Preview {
    TVSettingsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environment(TVReminderCenter.shared)
}
