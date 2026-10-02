//
//  NotificationManager.swift
//  IT21260438
//

import Foundation
import UserNotifications

/// Schedules the daily drink reminders and handles the "I drank a cup" notification action.
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    nonisolated static let categoryID = "WATER_REMINDER"
    nonisolated static let drinkActionID = "DRINK_NOW"

    private let center = UNUserNotificationCenter.current()

    private let messages = [
        "Stay hydrated! Have a glass of water now.",
        "Your body needs water. Take a few sips 💧",
        "Time for a refreshing cup of water!",
        "Keep the streak going, drink some water.",
        "A glass of water keeps you focused and fresh.",
    ]

    func configure() {
        center.delegate = self
        let drink = UNNotificationAction(identifier: Self.drinkActionID, title: "I drank a cup 💧", options: [])
        let category = UNNotificationCategory(identifier: Self.categoryID, actions: [drink], intentIdentifiers: [], options: [])
        center.setNotificationCategories([category])
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    /// Reminder times (minutes after midnight) from wake-up until bedtime. Bedtime may be after midnight.
    static func reminderTimes(wake: Int, sleep: Int, interval: Int) -> [Int] {
        guard interval > 0 else { return [] }
        let day = 24 * 60
        let end = sleep > wake ? sleep : sleep + day
        // iOS keeps at most 64 pending notifications per app.
        return Array(stride(from: wake, through: end, by: interval).prefix(60)).map { $0 % day }
    }

    static func currentReminderTimes() -> [Int] {
        let defaults = UserDefaults.standard
        return reminderTimes(
            wake: defaults.integer(forKey: AppSettings.Key.wakeMinutes),
            sleep: defaults.integer(forKey: AppSettings.Key.sleepMinutes),
            interval: defaults.integer(forKey: AppSettings.Key.reminderInterval)
        )
    }

    func rescheduleReminders() {
        center.removeAllPendingNotificationRequests()
        guard UserDefaults.standard.bool(forKey: AppSettings.Key.remindersEnabled) else { return }

        for (index, minutes) in Self.currentReminderTimes().enumerated() {
            var components = DateComponents()
            components.hour = minutes / 60
            components.minute = minutes % 60
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let content = makeContent(body: messages[index % messages.count])
            center.add(UNNotificationRequest(identifier: "reminder-\(minutes)", content: content, trigger: trigger))
        }
    }

    func sendTestNotification() {
        let content = makeContent(body: "This is how your water reminders will look 💧")
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        center.add(UNNotificationRequest(identifier: "test-\(UUID().uuidString)", content: content, trigger: trigger))
    }

    private func makeContent(body: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Time to drink water"
        content.body = body
        content.sound = .default
        content.categoryIdentifier = Self.categoryID
        return content
    }

    // MARK: UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard response.actionIdentifier == Self.drinkActionID else { return }
        await MainActor.run {
            let defaults = UserDefaults.standard
            RecordStore.add(
                amount: defaults.integer(forKey: AppSettings.Key.cupSize),
                goal: defaults.integer(forKey: AppSettings.Key.dailyGoal),
                in: PersistenceController.shared.container.viewContext
            )
        }
    }
}
