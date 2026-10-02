//
//  HistoryView.swift
//  IT21260438
//

import CoreData
import SwiftUI

enum HistoryRange: String, CaseIterable {
    case month = "Month"
    case year = "Year"

    var component: Calendar.Component { self == .month ? .month : .year }
}

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DrinkRecord.date, ascending: true)],
        animation: .default
    )
    private var records: FetchedResults<DrinkRecord>

    @AppStorage(AppSettings.Key.dailyGoal) private var dailyGoal = AppSettings.defaultGoal

    @State private var range: HistoryRange = .month
    @State private var anchor = Date.now
    @State private var editorMode: RecordEditorView.Mode?

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

        ScrollView {
            VStack(spacing: 0) {
                chartSection(stats)
                WeeklyCompletionView(days: stats.week(containing: .now))
                reportSection(stats)
            }
        }
        .background(Color.white)
        .sheet(item: $editorMode) { mode in
            RecordEditorView(mode: mode)
                .environment(\.managedObjectContext, context)
        }
    }

    // MARK: Chart

    private func chartSection(_ stats: HydrationStats) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 28) {
                periodButton("chevron.left", label: "Previous") { shiftPeriod(by: -1) }
                Text(periodTitle)
                    .font(.system(size: 18))
                    .foregroundStyle(.black)
                    .frame(minWidth: 150)
                    .contentTransition(.numericText())
                periodButton("chevron.right", label: "Next") { shiftPeriod(by: 1) }
                    .disabled(!canGoForward)
                    .opacity(canGoForward ? 1 : 0.35)
            }

            VStack(alignment: .leading, spacing: 4) {
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
                .frame(height: 230)

                if range == .month {
                    Text(anchor.formatted(.dateTime.month(.wide)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)

            RangeToggle(selection: $range)

            HStack {
                Spacer()
                Button {
                    editorMode = .add(.now)
                } label: {
                    HStack(spacing: 8) {
                        Text("Add record")
                            .font(.system(size: 17))
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .medium))
                    }
                    .foregroundStyle(.black)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 20)
        .padding(.bottom, 14)
    }

    private func periodButton(_ systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(white: 0.5))
                .frame(width: 34, height: 34)
                .background(Circle().fill(Theme.card))
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

    private func reportSection(_ stats: HydrationStats) -> some View {
        let now = Date.now
        let week = calendar.dateInterval(of: .weekOfYear, for: now) ?? DateInterval(start: now, duration: 7 * 86_400)
        let month = calendar.dateInterval(of: .month, for: now) ?? DateInterval(start: now, duration: 30 * 86_400)

        return VStack(alignment: .leading, spacing: 0) {
            Text("Drink water report")
                .font(.system(size: 24))
                .foregroundStyle(.black)
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                ReportRow(color: Theme.reportGreen, title: "Weekly average", value: "\(stats.averageIntake(in: week)) ml / day")
                Divider()
                ReportRow(color: Theme.primary, title: "Monthly average", value: "\(stats.averageIntake(in: month)) ml / day")
                Divider()
                ReportRow(color: Theme.reportOrange, title: "Average completion", value: "\(Int((stats.averageCompletion(in: month) * 100).rounded())) %")
                Divider()
            }
            .padding(.horizontal, 36)
        }
        .padding(.bottom, 32)
    }
}

private struct ReportRow: View {
    let color: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.system(size: 17))
                .foregroundStyle(.black)
            Spacer()
            Text(value)
                .font(.system(size: 17))
                .foregroundStyle(Theme.primary)
                .contentTransition(.numericText())
        }
        .padding(.vertical, 24)
    }
}

/// Two-segment Month / Year switch styled like the design.
struct RangeToggle: View {
    @Binding var selection: HistoryRange
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(HistoryRange.allCases, id: \.self) { item in
                Text(item.rawValue)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(selection == item ? Color.black : Color.white)
                    .frame(width: 128, height: 42)
                    .background {
                        if selection == item {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.white)
                                .padding(3)
                                .matchedGeometryEffect(id: "segment", in: namespace)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.snappy) { selection = item }
                    }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAddTraits(selection == item ? .isSelected : [])
            }
        }
        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.segmentFill))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.primary, lineWidth: 1.5))
    }
}

#Preview {
    HistoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
