//
//  Theme.swift
//  IT21260438
//

import SwiftUI

enum Theme {
    static let primary = Color(red: 0.24, green: 0.61, blue: 0.98)
    static let primaryLight = Color(red: 0.86, green: 0.93, blue: 1.0)
    static let bubble = Color(red: 0.86, green: 0.93, blue: 0.99)
    static let track = Color(white: 0.88)
    static let card = Color(white: 0.96)
    static let mutedIcon = Color(white: 0.58)
    static let weekCircle = Color(red: 0.26, green: 0.54, blue: 0.95)
    static let segmentFill = Color(red: 0.4, green: 0.7, blue: 0.99)
    static let reportGreen = Color(red: 0.2, green: 0.72, blue: 0.29)
    static let reportOrange = Color(red: 0.98, green: 0.66, blue: 0.2)

    static let headerGradient = LinearGradient(
        colors: [Color(red: 0.38, green: 0.76, blue: 0.99), Color(red: 0.24, green: 0.6, blue: 0.98)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

/// Slightly shrinks a button while it is pressed.
struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Fills the bottom `level` fraction of its rect, with a gentle wave on top.
struct WaterLevelShape: Shape {
    var level: CGFloat

    nonisolated var animatableData: CGFloat {
        get { level }
        set { level = newValue }
    }

    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        guard level > 0 else { return path }
        let top = rect.maxY - rect.height * min(level, 1)
        let amplitude = level >= 1 ? 0 : rect.height * 0.05
        path.move(to: CGPoint(x: rect.minX, y: top))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: top),
            control1: CGPoint(x: rect.minX + rect.width * 0.35, y: top - amplitude),
            control2: CGPoint(x: rect.minX + rect.width * 0.65, y: top + amplitude)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
