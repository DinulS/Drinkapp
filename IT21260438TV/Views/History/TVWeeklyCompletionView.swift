//
//  TVWeeklyCompletionView.swift
//  IT21260438TV
//

import SwiftUI

/// Blue gradient card with one bubble per day of the current week.
struct TVWeeklyCompletionView: View {
    let days: [DaySummary]

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text("Weekly completion")
                .font(.title3)
                .foregroundStyle(.white)

            HStack(spacing: 0) {
                ForEach(days) { day in
                    VStack(spacing: 14) {
                        TVDayBubble(completion: day.completion, isToday: Calendar.current.isDateInToday(day.day))
                        Text(day.day.formatted(.dateTime.weekday(.abbreviated)))
                            .font(.callout)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(day.day.formatted(.dateTime.weekday(.wide))): \(Int(min(day.completion, 1) * 100)) percent")
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.headerGradient, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

/// Day bubble filled with water up to the day's completion, with fonts scaled to its size.
struct TVDayBubble: View {
    let completion: Double
    let isToday: Bool
    var size: CGFloat = 72

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.weekCircle)
            WaterLevelShape(level: min(completion, 1))
                .fill(.white.opacity(0.9))
                .clipShape(Circle())
            if completion >= 1 {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.38, weight: .bold))
                    .foregroundStyle(Theme.primary)
            } else if completion > 0 {
                Text("\(Int(completion * 100))%")
                    .font(.system(size: size * 0.24, weight: .bold))
                    .foregroundStyle(completion > 0.5 ? Theme.primary : .white)
            }
        }
        .frame(width: size, height: size)
        .overlay(Circle().stroke(.white, lineWidth: isToday ? 3 : 0))
        .animation(.easeInOut, value: completion)
    }
}
