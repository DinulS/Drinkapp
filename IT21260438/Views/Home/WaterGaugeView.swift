//
//  WaterGaugeView.swift
//  IT21260438
//

import SwiftUI

/// The light blue hill at the bottom of the dial, clipped to the dial circle.
struct HillShape: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + h * 0.9))
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.minY + h * 0.645),
            control1: CGPoint(x: rect.minX + w * 0.24, y: rect.minY + h * 0.9),
            control2: CGPoint(x: rect.minX + w * 0.32, y: rect.minY + h * 0.645)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.9),
            control1: CGPoint(x: rect.minX + w * 0.68, y: rect.minY + h * 0.645),
            control2: CGPoint(x: rect.minX + w * 0.76, y: rect.minY + h * 0.9)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path.intersection(Path(ellipseIn: rect))
    }
}

/// Progress arc + dial with today's intake, the "drink" button and the cup switcher.
struct WaterGaugeView: View {
    let intake: Int
    let goal: Int
    let cupSize: Int
    let size: CGFloat
    let onDrink: () -> Void
    let onSwitchCup: () -> Void

    /// Arc starts slightly below the left edge and sweeps over the top to slightly below the right edge.
    private let startAngle = 172.0
    private let sweep = 196.0

    private var progress: Double {
        goal > 0 ? min(Double(intake) / Double(goal), 1) : 0
    }

    var body: some View {
        let lineWidth = max(size * 0.022, 6)

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

            switchCupButton
                .position(x: size * 0.88, y: size * 0.8)
        }
        .frame(width: size, height: size)
    }

    private func dial(diameter d: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(.white)
                .shadow(color: .black.opacity(0.12), radius: 8, y: 2)

            Button(action: onDrink) {
                ZStack {
                    HillShape().fill(Theme.primaryLight)
                    VStack(spacing: d * 0.01) {
                        Text("\(cupSize) ml")
                            .font(.system(size: d * 0.05))
                            .foregroundStyle(.black)
                        CupIcon(size: d * 0.16)
                    }
                    .position(x: d / 2, y: d * 0.82)
                }
                .contentShape(HillShape())
            }
            .buttonStyle(PressScaleButtonStyle())
            .accessibilityLabel("Drink \(cupSize) millilitres")

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
            .allowsHitTesting(false)
        }
        .frame(width: d, height: d)
    }

    private var switchCupButton: some View {
        Button(action: onSwitchCup) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.18), radius: 6, y: 2)
                CupIcon(size: size * 0.075, showPlus: false)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: size * 0.026, weight: .bold))
                    .foregroundStyle(Theme.primary)
                    .padding(size * 0.009)
                    .background(Circle().fill(.white).shadow(color: .black.opacity(0.15), radius: 2))
                    .offset(x: size * 0.012, y: size * 0.008)
            }
            .frame(width: size * 0.135, height: size * 0.135)
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityLabel("Switch cup size")
    }
}

#Preview {
    WaterGaugeView(intake: 800, goal: 2140, cupSize: 200, size: 340, onDrink: {}, onSwitchCup: {})
}
