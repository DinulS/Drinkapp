//
//  WeeklyCompletionView.swift
//  IT21260438
//

import SwiftUI

/// Blue gradient card with one bubble per day of the current week.
struct WeeklyCompletionView: View {
    let days: [DaySummary]

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Weekly completion")
                .font(.system(size: 24))
                .foregroundStyle(.white)

            HStack(spacing: 0) {
                ForEach(days) { day in
                    VStack(spacing: 12) {
                        DayCompletionBubble(
                            completion: day.completion,
                            isToday: Calendar.current.isDateInToday(day.day)
                        )
                        .frame(width: 46, height: 46)

                        Text(day.day.formatted(.dateTime.weekday(.abbreviated)))
                            .font(.system(size: 17))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(day.day.formatted(.dateTime.weekday(.wide))): \(Int(min(day.completion, 1) * 100)) percent")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.headerGradient)
    }
}

struct DayCompletionBubble: View {
    let completion: Double
    let isToday: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.weekCircle)
            WaterLevelShape(level: min(completion, 1))
                .fill(.white.opacity(0.9))
                .clipShape(Circle())
            if completion >= 1 {
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.primary)
            } else if completion > 0 {
                Text("\(Int(completion * 100))%")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(completion > 0.5 ? Theme.primary : .white)
            }
        }
        .overlay(Circle().stroke(.white, lineWidth: isToday ? 2 : 0))
        .animation(.easeInOut, value: completion)
    }
}
