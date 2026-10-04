//
//  TVControls.swift
//  IT21260438TV
//

import SwiftUI

/// Lifts a custom-drawn button with a soft blue glow when it has focus, like the system card effect.
struct TVLiftButtonStyle: ButtonStyle {
    var focusScale: CGFloat = 1.05

    func makeBody(configuration: Configuration) -> some View {
        LiftBody(configuration: configuration, focusScale: focusScale)
    }

    private struct LiftBody: View {
        let configuration: ButtonStyleConfiguration
        let focusScale: CGFloat
        @Environment(\.isFocused) private var isFocused

        var body: some View {
            configuration.label
                .scaleEffect(isFocused ? (configuration.isPressed ? focusScale - 0.03 : focusScale) : 1)
                .shadow(color: Theme.primary.opacity(isFocused ? 0.45 : 0), radius: isFocused ? 36 : 0, y: isFocused ? 16 : 0)
                .animation(.easeOut(duration: 0.2), value: isFocused)
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
        }
    }
}

/// A value with − / + buttons on either side. Replaces `Stepper` and `DatePicker`, which tvOS doesn't have.
struct TVAdjuster: View {
    let title: String
    let value: String
    var valueWidth: CGFloat = 220
    let onDecrease: () -> Void
    let onIncrease: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 24) {
                Button(action: onDecrease) {
                    Image(systemName: "minus")
                        .font(.title3.weight(.semibold))
                        .frame(width: 40, height: 40)
                }
                .accessibilityLabel("Decrease \(title)")

                Text(value)
                    .font(.title2.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(width: valueWidth)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: value)

                Button(action: onIncrease) {
                    Image(systemName: "plus")
                        .font(.title3.weight(.semibold))
                        .frame(width: 40, height: 40)
                }
                .accessibilityLabel("Increase \(title)")
            }
        }
    }
}
