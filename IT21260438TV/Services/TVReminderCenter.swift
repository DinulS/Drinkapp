//
//  TVReminderCenter.swift
//  IT21260438TV
//

import Foundation
import Observation
import UserNotifications

/// Drink reminders on Apple TV.
///
/// tvOS can't show notification banners, sounds or actions, so a reminder is delivered two ways:
/// an in-app alert while the app is open, and a badge on the app icon (via badge-only local
/// notifications) while it is closed.
@Observable
final class TVReminderCenter {
    static let shared = TVReminderCenter()

    /// Drives the in-app reminder alert.
    var isReminderPresented = false
    private(set) var message = ""

    private let center = UNUserNotificationCenter.current()
    @ObservationIgnored private var messageIndex = 0

    private let messages = [
        "Stay hydrated! Have a glass of water now.",
        "Your body needs water. Take a few sips 💧",
        "Time for a refreshing cup of water!",
        "Keep the streak going, drink some water.",
        "A glass of water keeps you focused and fresh.",
    ]

    func presentReminder() {
        message = messages[messageIndex % messages.count]
        messageIndex += 1
        isReminderPresented = true
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.badge])
        } catch {
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    /// Schedules a badge-only notification at every reminder time, so the app icon is marked while the app is closed.
    func rescheduleReminders() {
        center.removeAllPendingNotificationRequests()
        guard UserDefaults.standard.bool(forKey: AppSettings.Key.remindersEnabled) else {
            clearBadge()
            return
        }

        for minutes in Self.currentReminderTimes() {
            var components = DateComponents()
            components.hour = minutes / 60
            components.minute = minutes % 60
            let content = UNMutableNotificationContent()
            content.badge = 1
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            center.add(UNNotificationRequest(identifier: "reminder-\(minutes)", content: content, trigger: trigger))
        }
    }

    func clearBadge() {
        center.setBadgeCount(0)
    }

    // MARK: Schedule

    /// Reminder times (minutes after midnight) from wake-up until bedtime. Bedtime may be after midnight.
    /// Same schedule as the iOS app.
    static func reminderTimes(wake: Int, sleep: Int, interval: Int) -> [Int] {
        guard interval > 0 else { return [] }
        let day = 24 * 60
        let end = sleep > wake ? sleep : sleep + day
        // The system keeps at most 64 pending notifications per app.
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

    /// The first reminder strictly after `date`, rolling over to tomorrow once today's are over.
    static func nextReminder(after date: Date, times: [Int]) -> Date? {
        let times = times.sorted()
        guard let first = times.first else { return nil }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        for minutes in times {
            if let reminder = calendar.date(byAdding: .minute, value: minutes, to: startOfDay), reminder > date {
                return reminder
            }
        }
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return nil }
        return calendar.date(byAdding: .minute, value: first, to: tomorrow)
    }
}
