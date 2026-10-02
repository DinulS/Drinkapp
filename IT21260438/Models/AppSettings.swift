//
//  AppSettings.swift
//  IT21260438
//

import Foundation

enum Gender: String, CaseIterable, Identifiable {
    case male
    case female

    var id: String { rawValue }
    var title: String { self == .male ? "Male" : "Female" }
}

/// UserDefaults keys, defaults and helpers shared by `@AppStorage` properties and the notification scheduler.
enum AppSettings {
    enum Key {
        static let dailyGoal = "dailyGoal"
        static let cupSize = "cupSize"
        static let autoGoal = "autoGoal"
        static let weight = "weight"
        static let gender = "gender"
        static let remindersEnabled = "remindersEnabled"
        static let reminderInterval = "reminderInterval"
        static let wakeMinutes = "wakeMinutes"
        static let sleepMinutes = "sleepMinutes"
        static let didAskNotifications = "didAskNotifications"
    }

    static let defaultWeight = 60
    static let defaultGender = Gender.male
    static let defaultGoal = recommendedGoal(weight: defaultWeight, gender: defaultGender)
    static let defaultCup = 200
    static let defaultInterval = 60
    static let defaultWake = 7 * 60
    static let defaultSleep = 22 * 60

    static let cupSizes = [100, 150, 200, 250, 300, 400, 500, 600]
    static let intervals = [30, 45, 60, 90, 120, 180]
    static let goalRange = 500...6000
    static let cupRange = 10...2000

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            Key.dailyGoal: defaultGoal,
            Key.cupSize: defaultCup,
            Key.autoGoal: true,
            Key.weight: defaultWeight,
            Key.gender: defaultGender.rawValue,
            Key.remindersEnabled: true,
            Key.reminderInterval: defaultInterval,
            Key.wakeMinutes: defaultWake,
            Key.sleepMinutes: defaultSleep,
        ])
    }

    /// Roughly 35 ml per kg for men and 31 ml per kg for women, rounded to 10 ml.
    static func recommendedGoal(weight: Int, gender: Gender) -> Int {
        let perKg: Double = gender == .male ? 35 : 31
        return Int((Double(weight) * perKg / 10).rounded()) * 10
    }

    // MARK: Time-of-day helpers (times are stored as minutes after midnight)

    static func date(fromMinutes minutes: Int, on day: Date = .now) -> Date {
        let start = Calendar.current.startOfDay(for: day)
        return Calendar.current.date(byAdding: .minute, value: minutes, to: start) ?? start
    }

    static func minutes(from date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    static func intervalLabel(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) min" }
        if minutes % 60 == 0 { return "\(minutes / 60) h" }
        return "\(minutes / 60) h \(minutes % 60) min"
    }
}
