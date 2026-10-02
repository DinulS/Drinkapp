//
//  HistoryCharts.swift
//  IT21260438
//

import Charts
import SwiftUI

private let percentTicks: [Double] = [0, 20, 40, 60, 80, 100]

/// Daily completion bars for one month, with grid lines at the start of each week.
struct MonthCompletionChart: View {
    let points: [ChartPoint]
    let interval: DateInterval

    private var weekStarts: [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []
        var day = interval.start
        while day < interval.end {
            if calendar.component(.weekday, from: day) == calendar.firstWeekday {
                dates.append(day)
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return dates
    }

    var body: some View {
        Chart(points) { point in
            BarMark(
                x: .value("Day", point.date, unit: .day),
                y: .value("Completion", point.percent),
                width: .ratio(0.65)
            )
            .foregroundStyle(Theme.primary.gradient)
            .cornerRadius(2)
        }
        .chartXScale(domain: interval.start...interval.end)
        .chartYScale(domain: 0...100)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
            }
            AxisMarks(values: weekStarts) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.6))
                AxisTick(stroke: StrokeStyle(lineWidth: 0.8))
                AxisValueLabel(format: .dateTime.day())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: percentTicks) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                AxisValueLabel()
            }
        }
        .overlay {
            if points.isEmpty { EmptyChartLabel() }
        }
    }
}

/// Average monthly completion bars for one year.
struct YearCompletionChart: View {
    let points: [ChartPoint]
    let interval: DateInterval

    var body: some View {
        Chart(points) { point in
            BarMark(
                x: .value("Month", point.date, unit: .month),
                y: .value("Completion", point.percent),
                width: .ratio(0.6)
            )
            .foregroundStyle(Theme.primary.gradient)
            .cornerRadius(3)
        }
        .chartXScale(domain: interval.start...interval.end)
        .chartYScale(domain: 0...100)
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.6))
                AxisTick()
                AxisValueLabel(format: .dateTime.month(.narrow))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: percentTicks) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                AxisValueLabel()
            }
        }
        .overlay {
            if points.isEmpty { EmptyChartLabel() }
        }
    }
}

private struct EmptyChartLabel: View {
    var body: some View {
        Text("No records yet")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
}
