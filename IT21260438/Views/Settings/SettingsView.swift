//
//  SettingsView.swift
//  IT21260438
//

import CoreData
import SwiftUI
import UIKit
import UserNotifications

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.scenePhase) private var scenePhase

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
    @State private var testSent = false

    private var reminderTimes: [Int] {
        NotificationManager.reminderTimes(wake: wakeMinutes, sleep: sleepMinutes, interval: reminderInterval)
    }

    private var cupOptions: [Int] {
        Array(Set(AppSettings.cupSizes + [cupSize])).sorted()
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        Form {
            reminderSection
            goalSection

            Section("Cup") {
                Picker("Default cup size", selection: $cupSize) {
                    ForEach(cupOptions, id: \.self) { size in
                        Text("\(size) ml").tag(size)
                    }
                }
            }

            Section {
                Button("Clear all records", role: .destructive) { showClearConfirm = true }
            } header: {
                Text("Data")
            } footer: {
                Text("Records are stored only on this device.")
            }

            Section("About") {
                LabeledContent("Version", value: appVersion)
            }
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

    private var reminderSection: some View {
        Section {
            Toggle(isOn: remindersBinding) {
                Label("Drink reminders", systemImage: "bell.fill")
            }
            .tint(Theme.primary)

            if authorization == .denied {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notifications are turned off for this app in iOS Settings.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("Open Settings", action: openSystemSettings)
                        .font(.footnote.weight(.semibold))
                }
            }

            if remindersEnabled {
                DatePicker("Wake-up time", selection: timeBinding($wakeMinutes), displayedComponents: .hourAndMinute)
                DatePicker("Bedtime", selection: timeBinding($sleepMinutes), displayedComponents: .hourAndMinute)
                Picker("Remind every", selection: $reminderInterval) {
                    ForEach(AppSettings.intervals, id: \.self) { minutes in
                        Text(AppSettings.intervalLabel(minutes)).tag(minutes)
                    }
                }
                LabeledContent("Reminders per day", value: "\(reminderTimes.count)")
                Button("Send a test reminder") {
                    NotificationManager.shared.sendTestNotification()
                    testSent = true
                }
            }
        } header: {
            Text("Reminders")
        } footer: {
            if testSent && remindersEnabled {
                Text("A test reminder arrives in 5 seconds. Go to the Home Screen to see it as a banner.")
            }
        }
    }

    private var goalSection: some View {
        Section {
            Toggle("Calculate from body weight", isOn: $autoGoal)
                .tint(Theme.primary)

            if autoGoal {
                Picker("Gender", selection: $gender) {
                    ForEach(Gender.allCases) { gender in
                        Text(gender.title).tag(gender)
                    }
                }
                .pickerStyle(.segmented)
                Stepper("Weight: \(weight) kg", value: $weight, in: 20...200)
            } else {
                Stepper("Target: \(dailyGoal) ml", value: $dailyGoal, in: AppSettings.goalRange, step: 50)
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

    private var remindersBinding: Binding<Bool> {
        Binding(
            get: { remindersEnabled },
            set: { isOn in
                if isOn {
                    Task { await enableReminders() }
                } else {
                    remindersEnabled = false
                }
            }
        )
    }

    private func timeBinding(_ minutes: Binding<Int>) -> Binding<Date> {
        Binding(
            get: { AppSettings.date(fromMinutes: minutes.wrappedValue) },
            set: { minutes.wrappedValue = AppSettings.minutes(from: $0) }
        )
    }

    private func enableReminders() async {
        switch await NotificationManager.shared.authorizationStatus() {
        case .notDetermined:
            remindersEnabled = await NotificationManager.shared.requestAuthorization()
        case .denied:
            remindersEnabled = false
        default:
            remindersEnabled = true
        }
        await refreshAuthorization()
    }

    private func refreshAuthorization() async {
        authorization = await NotificationManager.shared.authorizationStatus()
    }

    private func reschedule() {
        NotificationManager.shared.rescheduleReminders()
    }

    private func recalculateGoal() {
        guard autoGoal else { return }
        dailyGoal = AppSettings.recommendedGoal(weight: weight, gender: gender)
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
