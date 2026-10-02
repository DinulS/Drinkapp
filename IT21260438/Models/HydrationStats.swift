//
//  HydrationStats.swift
//  IT21260438
//

import Foundation

struct DrinkEntry {
    let date: Date
    let amount: Int
    let goal: Int
}

struct DaySummary: Identifiable {
    let day: Date
    let total: Int
    let goal: Int

    var id: Date { day }
    var completion: Double { goal > 0 ? Double(total) / Double(goal) : 0 }
}

struct ChartPoint: Identifiable {
    let date: Date
    let percent: Double

    var id: Date { date }
}

/// Aggregates drink records per day and derives the averages shown on the History tab.
struct HydrationStats {
    private let summaries: [Date: DaySummary]
    private let calendar: Calendar
    private let currentGoal: Int

    init(entries: [DrinkEntry], currentGoal: Int, calendar: Calendar = .current, now: Date = .now) {
        let today = calendar.startOfDay(for: now)
        let fallbackGoal = max(currentGoal, 1)

        var totals: [Date: Int] = [:]
        var latestGoal: [Date: (date: Date, goal: Int)] = [:]
        for entry in entries {
            let day = calendar.startOfDay(for: entry.date)
            totals[day, default: 0] += entry.amount
            if let latest = latestGoal[day], latest.date > entry.date { continue }
            latestGoal[day] = (entry.date, entry.goal)
        }

        var summaries: [Date: DaySummary] = [:]
        for (day, total) in totals {
            // Today always follows the current target; past days keep the target they were logged with.
            let storedGoal = latestGoal[day]?.goal ?? 0
            let goal = (day == today || storedGoal <= 0) ? fallbackGoal : storedGoal
            summaries[day] = DaySummary(day: day, total: total, goal: goal)
        }

        self.summaries = summaries
        self.calendar = calendar
        self.currentGoal = fallbackGoal
    }

    init(records: some Sequence<DrinkRecord>, currentGoal: Int, calendar: Calendar = .current, now: Date = .now) {
        let entries = records.compactMap { record in
            record.date.map { DrinkEntry(date: $0, amount: Int(record.amount), goal: Int(record.goal)) }
        }
        self.init(entries: entries, currentGoal: currentGoal, calendar: calendar, now: now)
    }

    func summary(for date: Date) -> DaySummary {
        let day = calendar.startOfDay(for: date)
        return summaries[day] ?? DaySummary(day: day, total: 0, goal: currentGoal)
    }

    /// Days inside `interval` that have at least one record.
    func loggedDays(in interval: DateInterval) -> [DaySummary] {
        summaries.values
            .filter { $0.day >= interval.start && $0.day < interval.end }
            .sorted { $0.day < $1.day }
    }

    func averageIntake(in interval: DateInterval) -> Int {
        let days = loggedDays(in: interval)
        guard !days.isEmpty else { return 0 }
        return days.reduce(0) { $0 + $1.total } / days.count
    }

    /// Average of each logged day's completion, capped at 100% per day. Range 0...1.
    func averageCompletion(in interval: DateInterval) -> Double {
        let days = loggedDays(in: interval)
        guard !days.isEmpty else { return 0 }
        return days.reduce(0.0) { $0 + min($1.completion, 1) } / Double(days.count)
    }

    func dailyPoints(in interval: DateInterval) -> [ChartPoint] {
        loggedDays(in: interval).map { ChartPoint(date: $0.day, percent: min($0.completion, 1) * 100) }
    }

    func monthlyPoints(in interval: DateInterval) -> [ChartPoint] {
        var points: [ChartPoint] = []
        var cursor = interval.start
        while cursor < interval.end {
            guard let month = calendar.dateInterval(of: .month, for: cursor) else { break }
            let completion = averageCompletion(in: month)
            if completion > 0 {
                points.append(ChartPoint(date: month.start, percent: completion * 100))
            }
            cursor = month.end
        }
        return points
    }

    func week(containing date: Date) -> [DaySummary] {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: date) else { return [] }
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: week.start).map { summary(for: $0) }
        }
    }
}
