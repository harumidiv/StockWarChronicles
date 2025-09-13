//
//  TagView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/01.
//

import SwiftUI

struct TagView: View {
    let name: String
    let color: Color
    var body: some View {
        Text(name)
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .foregroundColor(color.isLight() ? .black : .white)
            .background(color)
            .lineLimit(1)
            .clipShape(Capsule())
    }
}

#Preview {
    TagView(name: "タグ", color: .red)
}
