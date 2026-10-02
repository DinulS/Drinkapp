//
//  MascotView.swift
//  IT21260438
//

import SwiftUI

struct DropShape: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let x = rect.minX
        let y = rect.minY
        var path = Path()
        path.move(to: CGPoint(x: x + 0.5 * w, y: y))
        path.addCurve(
            to: CGPoint(x: x + w, y: y + 0.64 * h),
            control1: CGPoint(x: x + 0.62 * w, y: y + 0.2 * h),
            control2: CGPoint(x: x + w, y: y + 0.38 * h)
        )
        path.addCurve(
            to: CGPoint(x: x + 0.5 * w, y: y + h),
            control1: CGPoint(x: x + w, y: y + 0.86 * h),
            control2: CGPoint(x: x + 0.78 * w, y: y + h)
        )
        path.addCurve(
            to: CGPoint(x: x, y: y + 0.64 * h),
            control1: CGPoint(x: x + 0.22 * w, y: y + h),
            control2: CGPoint(x: x, y: y + 0.86 * h)
        )
        path.addCurve(
            to: CGPoint(x: x + 0.5 * w, y: y),
            control1: CGPoint(x: x, y: y + 0.38 * h),
            control2: CGPoint(x: x + 0.38 * w, y: y + 0.2 * h)
        )
        path.closeSubpath()
        return path
    }
}

/// The water drop character with glasses, drawn in a 100 × 120 point canvas.
struct MascotView: View {
    var cheering = false

    private let blue = Color(red: 0.2, green: 0.56, blue: 0.97)
    private let lightBlue = Color(red: 0.42, green: 0.74, blue: 1.0)
    private let frameColor = Color(white: 0.12)
    private let mouthColor = Color(red: 0.86, green: 0.16, blue: 0.22)

    var body: some View {
        ZStack {
            legs
            leftArm
            waveArm
            DropShape()
                .fill(LinearGradient(colors: [lightBlue, blue], startPoint: .top, endPoint: .bottom))
                .frame(width: 70, height: 90)
                .position(x: 50, y: 55)
            Ellipse()
                .fill(.white.opacity(0.55))
                .frame(width: 7, height: 15)
                .rotationEffect(.degrees(25))
                .position(x: 33, y: 45)
            glasses
            mouth
        }
        .frame(width: 100, height: 120)
        .phaseAnimator([false, true]) { content, up in
            content.offset(y: up ? -3 : 3)
        } animation: { _ in
            .easeInOut(duration: 1.4)
        }
        .accessibilityHidden(true)
    }

    private var legs: some View {
        ZStack {
            Capsule().fill(blue).frame(width: 9, height: 18).position(x: 41, y: 104)
            Capsule().fill(blue).frame(width: 9, height: 18).position(x: 59, y: 104)
            Ellipse().fill(blue).frame(width: 17, height: 8).position(x: 37, y: 113)
            Ellipse().fill(blue).frame(width: 17, height: 8).position(x: 63, y: 113)
        }
    }

    private var leftArm: some View {
        Capsule()
            .fill(blue)
            .frame(width: 8, height: 22)
            .rotationEffect(.degrees(28))
            .position(x: 12, y: 78)
    }

    private var waveArm: some View {
        ZStack(alignment: .top) {
            Capsule().fill(blue).frame(width: 8, height: 24)
            Circle().fill(blue).frame(width: 13, height: 13).offset(y: -6)
        }
        .frame(width: 13, height: 24)
        .phaseAnimator([false, true]) { content, raised in
            content.rotationEffect(.degrees(raised ? (cheering ? 20 : 35) : 60), anchor: .bottom)
        } animation: { _ in
            .easeInOut(duration: cheering ? 0.3 : 0.6)
        }
        .position(x: 87, y: 58)
    }

    private var glasses: some View {
        ZStack {
            ForEach([38.0, 62.0], id: \.self) { x in
                Circle()
                    .fill(.white)
                    .overlay(Circle().stroke(frameColor, lineWidth: 2.5))
                    .frame(width: 21, height: 21)
                    .position(x: x, y: 64)
                Circle()
                    .fill(.black)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().fill(.white).frame(width: 2.5, height: 2.5).offset(x: 1.5, y: -1.5))
                    .position(x: x + 1, y: 65)
            }
            Capsule().fill(frameColor).frame(width: 5, height: 2.5).position(x: 50, y: 62)
            Capsule().fill(frameColor).frame(width: 6, height: 2.5).position(x: 25, y: 62)
            Capsule().fill(frameColor).frame(width: 6, height: 2.5).position(x: 75, y: 62)
        }
    }

    private var mouth: some View {
        Circle()
            .trim(from: 0, to: 0.5)
            .fill(mouthColor)
            .frame(width: 14, height: 14)
            .position(x: 50, y: 78)
    }
}

/// Speech bubble with a small tail pointing to the mascot on the left.
struct SpeechBubbleShape: Shape {
    var tailSize: CGFloat = 12
    var cornerRadius: CGFloat = 18

    nonisolated func path(in rect: CGRect) -> Path {
        let bubble = CGRect(x: rect.minX + tailSize, y: rect.minY, width: rect.width - tailSize, height: rect.height)
        var path = Path(roundedRect: bubble, cornerRadius: cornerRadius, style: .continuous)
        let tailY = rect.minY + min(rect.height * 0.38, 40)
        path.move(to: CGPoint(x: bubble.minX + 1, y: tailY - tailSize * 0.75))
        path.addLine(to: CGPoint(x: rect.minX, y: tailY))
        path.addLine(to: CGPoint(x: bubble.minX + 1, y: tailY + tailSize * 0.75))
        path.closeSubpath()
        return path
    }
}

struct MascotHeader: View {
    let message: String
    var cheering = false

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            MascotView(cheering: cheering)
            Text(message)
                .font(.system(size: 17))
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
                .padding(.leading, 12 + 14)
                .padding(.trailing, 14)
                .padding(.vertical, 18)
                .frame(maxWidth: .infinity, minHeight: 92)
                .background(SpeechBubbleShape().fill(Theme.bubble))
                .contentTransition(.opacity)
                .animation(.easeInOut, value: message)
        }
    }
}

#Preview {
    MascotHeader(message: "Start drinking first cup of water!")
        .padding()
}
