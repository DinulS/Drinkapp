//
//  CupIcon.swift
//  IT21260438
//

import SwiftUI

/// Tapered cup body (wider at the top).
struct CupBodyShape: Shape {
    var taper: CGFloat = 0.14

    nonisolated func path(in rect: CGRect) -> Path {
        let inset = rect.width * taper
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// The lidded water cup used across the app.
struct CupIcon: View {
    var size: CGFloat
    var showPlus = true
    var fillLevel: CGFloat = 0.62

    var body: some View {
        let lineWidth = max(size * 0.065, 1.5)
        let bodyWidth = size * 0.7
        let bodyHeight = size * 0.78

        VStack(spacing: size * 0.02) {
            RoundedRectangle(cornerRadius: size * 0.04, style: .continuous)
                .stroke(Color.black, lineWidth: lineWidth)
                .frame(width: bodyWidth * 1.1, height: size * 0.1)

            ZStack {
                CupBodyShape()
                    .fill(Theme.primary)
                    .mask { WaterLevelShape(level: fillLevel) }
                CupBodyShape()
                    .stroke(Color.black, style: StrokeStyle(lineWidth: lineWidth, lineJoin: .round))
                if showPlus {
                    Image(systemName: "plus")
                        .font(.system(size: size * 0.26, weight: .heavy))
                        .foregroundStyle(.white)
                        .offset(y: bodyHeight * 0.16)
                }
            }
            .frame(width: bodyWidth, height: bodyHeight)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: 24) {
        CupIcon(size: 60)
        CupIcon(size: 40, showPlus: false, fillLevel: 0.3)
    }
}
