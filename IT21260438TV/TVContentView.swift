//
//  TVContentView.swift
//  IT21260438TV
//

import CoreData
import SwiftUI

enum TVTab: Hashable {
    case home
    case history
    case settings
}

struct TVContentView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.scenePhase) private var scenePhase

    @State private var selection: TVTab = .home
    @State private var reminders = TVReminderCenter.shared

    @AppStorage(AppSettings.Key.remindersEnabled) private var remindersEnabled = true
    @AppStorage(AppSettings.Key.didAskNotifications) private var didAskNotifications = false
    @AppStorage(AppSettings.Key.wakeMinutes) private var wakeMinutes = AppSettings.defaultWake
    @AppStorage(AppSettings.Key.sleepMinutes) private var sleepMinutes = AppSettings.defaultSleep
    @AppStorage(AppSettings.Key.reminderInterval) private var reminderInterval = AppSettings.defaultInterval
    @AppStorage(AppSettings.Key.cupSize) private var cupSize = AppSettings.defaultCup
    @AppStorage(AppSettings.Key.dailyGoal) private var dailyGoal = AppSettings.defaultGoal

    private var reminderTimes: [Int] {
        guard remindersEnabled else { return [] }
        return TVReminderCenter.reminderTimes(wake: wakeMinutes, sleep: sleepMinutes, interval: reminderInterval)
    }

    var body: some View {
        // The system tab bar sits at the top of the screen on tvOS and is reached by swiping up.
        TabView(selection: $selection) {
            Tab("Home", systemImage: "drop.fill", value: TVTab.home) {
                TVHomeView()
            }
            Tab("History", systemImage: "clock.arrow.circlepath", value: TVTab.history) {
                TVHistoryView()
            }
            Tab("Settings", systemImage: "gearshape.fill", value: TVTab.settings) {
                TVSettingsView()
            }
        }
        .environment(reminders)
        .alert("Time to drink water", isPresented: $reminders.isReminderPresented) {
            Button("I drank \(cupSize) ml 💧", action: drink)
            Button("Later", role: .cancel) {}
        } message: {
            Text(reminders.message)
        }
        .task { await setUpReminders() }
        .task(id: reminderTimes) { await showReminders(at: reminderTimes) }
        .onChange(of: scenePhase) {
            if scenePhase == .active { reminders.clearBadge() }
        }
    }

    /// Asks once for badge permission, then makes sure the reminder schedule is current.
    /// In-app reminders work without the permission, so reminders stay on either way.
    private func setUpReminders() async {
        if !didAskNotifications {
            didAskNotifications = true
            _ = await reminders.requestAuthorization()
        }
        reminders.rescheduleReminders()
        reminders.clearBadge()
    }

    /// Shows the in-app reminder at each reminder time while the app is open.
    private func showReminders(at times: [Int]) async {
        while let next = TVReminderCenter.nextReminder(after: .now, times: times) {
            do {
                try await Task.sleep(for: .seconds(next.timeIntervalSinceNow))
            } catch {
                return
            }
            reminders.presentReminder()
        }
    }

    private func drink() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            RecordStore.add(amount: cupSize, goal: dailyGoal, in: context)
        }
        reminders.clearBadge()
    }
}

#Preview {
    TVContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
