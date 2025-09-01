//
//  DashedLine.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/01.
//


import SwiftUI

// MARK: - HorizontalLine

struct HorizontalLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
    }
}

// MARK: - VerticalLine

struct VerticalLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        return path
    }
}

// MARK: - DashedLine

public struct DashedLine: View {
    public enum Direction {
        case horizontal
        case vertical
    }

    var direction: Direction
    var lineWidth: CGFloat
    var dash: [CGFloat]
    var color: Color

    public var body: some View {
        line.foregroundColor(color)
    }

    @ViewBuilder
    var line: some View {
        switch direction {
        case .horizontal:
            HorizontalLine()
                .stroke(style: StrokeStyle(lineWidth: lineWidth, dash: dash))
                .frame(height: lineWidth)
                .offset(y: lineWidth / 2)
        case .vertical:
            VerticalLine()
                .stroke(style: StrokeStyle(lineWidth: lineWidth, dash: dash))
                .frame(width: lineWidth)
                .offset(x: lineWidth / 2)
        }
    }

    public init(
        direction: Direction,
        lineWidth: CGFloat = 1.0,
        dash: [CGFloat] = [2, 2],
        color: Color = .gray
    ) {
        self.direction = direction
        self.lineWidth = lineWidth
        self.dash = dash
        self.color = color
    }
}

#Preview {
    DashedLine(direction: .horizontal)
    DashedLine(direction: .vertical)
}
