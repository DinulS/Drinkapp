//
//  IT21260438Tests.swift
//  IT21260438Tests
//
//  Created by Janith Kavinda on 2026-09-27.
//

import XCTest
@testable import IT21260438

@MainActor
final class IT21260438Tests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 1
        return calendar
    }

    private func date(_ day: Int, _ hour: Int = 9, month: Int = 10) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
    }

    // MARK: Reminder times

    func testReminderTimesFromWakeToBedtime() {
        let times = NotificationManager.reminderTimes(wake: 7 * 60, sleep: 10 * 60, interval: 60)
        XCTAssertEqual(times, [420, 480, 540, 600])
    }

    func testReminderTimesWrapPastMidnight() {
        let times = NotificationManager.reminderTimes(wake: 22 * 60, sleep: 60, interval: 90)
        XCTAssertEqual(times, [1320, 1410, 60])
    }

    func testReminderTimesAreCappedForNotificationLimit() {
        let times = NotificationManager.reminderTimes(wake: 0, sleep: 23 * 60 + 59, interval: 1)
        XCTAssertEqual(times.count, 60)
    }

    // MARK: Goal

    func testRecommendedGoal() {
        XCTAssertEqual(AppSettings.recommendedGoal(weight: 60, gender: .male), 2100)
        XCTAssertEqual(AppSettings.recommendedGoal(weight: 60, gender: .female), 1860)
    }

    // MARK: Stats

    func testDailyTotalsAndCompletion() {
        let entries = [
            DrinkEntry(date: date(1, 8), amount: 500, goal: 2000),
            DrinkEntry(date: date(1, 12), amount: 500, goal: 2000),
            DrinkEntry(date: date(2, 9), amount: 2500, goal: 2000),
        ]
        let stats = HydrationStats(entries: entries, currentGoal: 1500, calendar: calendar, now: date(3))

        XCTAssertEqual(stats.summary(for: date(1)).total, 1000)
        XCTAssertEqual(stats.summary(for: date(1)).completion, 0.5, accuracy: 0.001)
        XCTAssertEqual(stats.summary(for: date(3)).total, 0)
        // Today uses the current goal.
        XCTAssertEqual(stats.summary(for: date(3)).goal, 1500)

        let month = calendar.dateInterval(of: .month, for: date(1))!
        XCTAssertEqual(stats.averageIntake(in: month), 1750)
        // Day 2 is capped at 100%: (50% + 100%) / 2
        XCTAssertEqual(stats.averageCompletion(in: month), 0.75, accuracy: 0.001)
        XCTAssertEqual(stats.dailyPoints(in: month).map(\.percent), [50, 100])
    }

    func testWeekHasSevenDaysStartingOnFirstWeekday() {
        let stats = HydrationStats(entries: [], currentGoal: 2000, calendar: calendar, now: date(3))
        let week = stats.week(containing: date(7))
        XCTAssertEqual(week.count, 7)
        XCTAssertEqual(calendar.component(.weekday, from: week[0].day), 1)
    }

    func testMonthlyPointsSkipEmptyMonths() {
        let entries = [
            DrinkEntry(date: date(5, month: 3), amount: 1000, goal: 2000),
            DrinkEntry(date: date(5, month: 7), amount: 2000, goal: 2000),
        ]
        let stats = HydrationStats(entries: entries, currentGoal: 2000, calendar: calendar, now: date(3))
        let year = calendar.dateInterval(of: .year, for: date(1))!
        XCTAssertEqual(stats.monthlyPoints(in: year).map(\.percent), [50, 100])
    }
}
