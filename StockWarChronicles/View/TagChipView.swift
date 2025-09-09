//
//  TagChipView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/09.
//


import SwiftUI

struct TagChipView: View {
    let tag: Tag
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Button(action: {
                onTap()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }) {
                TagView(name: tag.name,
                        color: isSelected ? tag.color : Color.gray.opacity(0.2))
            }
        }
    }
}

#Preview {
    TagChipView(tag: .init(name: "タグ名", color: .blue), isSelected: true, onTap: { })
}
