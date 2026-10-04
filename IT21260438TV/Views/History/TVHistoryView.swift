//
//  TVHistoryView.swift
//  IT21260438TV
//

import CoreData
import SwiftUI

enum TVHistoryRange: String, CaseIterable, Identifiable {
    case month = "Month"
    case year = "Year"

    var id: String { rawValue }
    var component: Calendar.Component { self == .month ? .month : .year }
}

/// Completion chart on the left; weekly completion and the averages report on the right.
struct TVHistoryView: View {
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DrinkRecord.date, ascending: true)],
        animation: .default
    )
    private var records: FetchedResults<DrinkRecord>

    @AppStorage(AppSettings.Key.dailyGoal) private var dailyGoal = AppSettings.defaultGoal

    @State private var range: TVHistoryRange = .month
    @State private var anchor = Date.now
    @State private var editorMode: TVRecordEditorView.Mode?

    private let calendar = Calendar.current

    private var periodInterval: DateInterval {
        calendar.dateInterval(of: range.component, for: anchor)
            ?? DateInterval(start: anchor, duration: 30 * 86_400)
    }

    private var periodTitle: String {
        switch range {
        case .month: anchor.formatted(.dateTime.month(.wide).year())
        case .year: anchor.formatted(.dateTime.year())
        }
    }

    private var canGoForward: Bool {
        guard let next = calendar.date(byAdding: range.component, value: 1, to: anchor),
              let nextInterval = calendar.dateInterval(of: range.component, for: next)
        else { return false }
        return nextInterval.start <= .now
    }

    var body: some View {
        let stats = HydrationStats(records: records, currentGoal: dailyGoal)

        HStack(alignment: .top, spacing: 60) {
            chartPanel(stats)
                .frame(maxWidth: .infinity)

            VStack(spacing: 40) {
                TVWeeklyCompletionView(days: stats.week(containing: .now))
                reportPanel(stats)
            }
            .frame(width: 720)
        }
        .background(Color.white.ignoresSafeArea())
        .sheet(item: $editorMode) { mode in
            TVRecordEditorView(mode: mode)
                .environment(\.managedObjectContext, context)
        }
    }

    // MARK: Chart

    private func chartPanel(_ stats: HydrationStats) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 28) {
                periodButton("chevron.left", label: "Previous") { shiftPeriod(by: -1) }
                Text(periodTitle)
                    .font(.title3)
                    .foregroundStyle(.black)
                    .frame(minWidth: 300)
                    .contentTransition(.numericText())
                periodButton("chevron.right", label: "Next") { shiftPeriod(by: 1) }
                    .disabled(!canGoForward)

                Spacer()

                Picker("Range", selection: $range.animation(.snappy)) {
                    ForEach(TVHistoryRange.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 380)
            }

            Text("(%)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Group {
                switch range {
                case .month:
                    MonthCompletionChart(points: stats.dailyPoints(in: periodInterval), interval: periodInterval)
                case .year:
                    YearCompletionChart(points: stats.monthlyPoints(in: periodInterval), interval: periodInterval)
                }
            }
            .frame(height: 400)

            HStack {
                if range == .month {
                    Text(anchor.formatted(.dateTime.month(.wide)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    editorMode = .add(.now)
                } label: {
                    Label("Add record", systemImage: "plus")
                }
            }
        }
    }

    private func periodButton(_ systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline)
        }
        .accessibilityLabel(label)
    }

    private func shiftPeriod(by value: Int) {
        guard let date = calendar.date(byAdding: range.component, value: value, to: anchor) else { return }
        withAnimation(.snappy) {
            anchor = min(date, .now)
        }
    }

    // MARK: Report

    private func reportPanel(_ stats: HydrationStats) -> some View {
        let now = Date.now
        let week = calendar.dateInterval(of: .weekOfYear, for: now) ?? DateInterval(start: now, duration: 7 * 86_400)
        let month = calendar.dateInterval(of: .month, for: now) ?? DateInterval(start: now, duration: 30 * 86_400)

        return VStack(alignment: .leading, spacing: 0) {
            Text("Drink water report")
                .font(.title3)
                .foregroundStyle(.black)
                .padding(.bottom, 8)

            TVReportRow(color: Theme.reportGreen, title: "Weekly average", value: "\(stats.averageIntake(in: week)) ml / day")
            Divider()
            TVReportRow(color: Theme.primary, title: "Monthly average", value: "\(stats.averageIntake(in: month)) ml / day")
            Divider()
            TVReportRow(color: Theme.reportOrange, title: "Average completion", value: "\(Int((stats.averageCompletion(in: month) * 100).rounded())) %")
        }
    }
}

private struct TVReportRow: View {
    let color: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 20) {
            Circle()
                .fill(color)
                .frame(width: 14, height: 14)
            Text(title)
                .foregroundStyle(.black)
            Spacer()
            Text(value)
                .foregroundStyle(Theme.primary)
                .contentTransition(.numericText())
        }
        .font(.body)
        .padding(.vertical, 22)
    }
}

#Preview {
    TVHistoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
