//
//  TVWaterGauge.swift
//  IT21260438TV
//

import SwiftUI

/// The iOS progress arc and dial, drawn without inner buttons so the whole gauge can be one focusable target.
struct TVWaterGauge: View {
    let intake: Int
    let goal: Int
    let cupSize: Int
    let size: CGFloat

    /// Arc starts slightly below the left edge and sweeps over the top to slightly below the right edge.
    private let startAngle = 172.0
    private let sweep = 196.0

    private var progress: Double {
        goal > 0 ? min(Double(intake) / Double(goal), 1) : 0
    }

    var body: some View {
        let lineWidth = max(size * 0.022, 8)

        ZStack {
            Circle()
                .trim(from: 0, to: sweep / 360)
                .stroke(Theme.track, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(startAngle))
                .padding(lineWidth / 2)

            Circle()
                .trim(from: 0, to: sweep / 360 * progress)
                .stroke(Theme.primary, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(startAngle))
                .padding(lineWidth / 2)
                .opacity(progress > 0 ? 1 : 0)
                .animation(.spring(duration: 0.8), value: progress)

            dial(diameter: size * 0.82)

            Image(systemName: "heart.slash.fill")
                .font(.system(size: size * 0.075))
                .foregroundStyle(Theme.mutedIcon)
                .position(x: size * 0.025, y: size * 0.665)

            ZStack(alignment: .topTrailing) {
                Image(systemName: "drop.fill")
                    .font(.system(size: size * 0.07))
                Image(systemName: "sparkles")
                    .font(.system(size: size * 0.035))
                    .offset(x: size * 0.03, y: -size * 0.02)
            }
            .foregroundStyle(Theme.primary)
            .symbolEffect(.bounce, value: progress >= 1)
            .position(x: size * 0.975, y: size * 0.665)
        }
        .frame(width: size, height: size)
    }

    private func dial(diameter d: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(.white)
                .shadow(color: .black.opacity(0.12), radius: 12, y: 3)

            HillShape()
                .fill(Theme.primaryLight)

            VStack(spacing: d * 0.01) {
                Text("\(cupSize) ml")
                    .font(.system(size: d * 0.05))
                    .foregroundStyle(.black)
                CupIcon(size: d * 0.16)
            }
            .position(x: d / 2, y: d * 0.82)

            VStack(spacing: d * 0.035) {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("\(intake)")
                        .foregroundStyle(Theme.primary)
                        .contentTransition(.numericText(value: Double(intake)))
                    Text("/\(goal)")
                        .foregroundStyle(.black)
                    Text("ml")
                        .font(.system(size: d * 0.085))
                        .foregroundStyle(.black)
                }
                .font(.system(size: d * 0.14))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, d * 0.08)
                .animation(.snappy, value: intake)

                Text("Daily Drink Target")
                    .font(.system(size: d * 0.052, weight: .semibold))
                    .foregroundStyle(.black)
            }
            .offset(y: -d * 0.07)
        }
        .frame(width: d, height: d)
    }
}

#Preview {
    TVWaterGauge(intake: 800, goal: 2140, cupSize: 200, size: 520)
}
