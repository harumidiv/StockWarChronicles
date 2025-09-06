//
//  ScreenBackground.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/06.
//

import SwiftUI

struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            Color.yellow.opacity(0.1)
                .ignoresSafeArea()
            content
        }
    }
}

extension View {
    func screenBackground() -> some View {
        self.modifier(ScreenBackground())
    }
}
