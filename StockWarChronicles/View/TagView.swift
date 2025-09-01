//
//  TagView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/01.
//

import SwiftUI

struct TagView: View {
    let name: String
    let foregroundColor: Color
    let backgroundColror: Color
    var body: some View {
        Text(name)
            .font(.footnote)
            .fontWeight(.bold)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundColor(foregroundColor)
            .background(backgroundColror)
            .lineLimit(1)
            .clipShape(Capsule())
    }
}

#Preview {
    TagView(name: "タグ", foregroundColor: .red, backgroundColror: .green)
}
