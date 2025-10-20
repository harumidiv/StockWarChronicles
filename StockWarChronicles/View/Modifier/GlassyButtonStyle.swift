//
//  GlassyButtonStyle.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/10.
//


import SwiftUI

struct GlassyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .foregroundColor(.primary)
            // このモディファイアは自作か、仮のものを設定
            .glassEffect()
            .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
            // タップ時のフィードバック
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
extension View {
    func glassButtonStyle() -> some View {
        self.buttonStyle(GlassyButtonStyle())
    }
}
