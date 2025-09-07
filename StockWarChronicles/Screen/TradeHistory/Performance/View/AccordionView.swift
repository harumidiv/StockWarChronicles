//
//  AccordionView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/06.
//


import SwiftUI

// MARK: - AccordionView

struct AccordionView<Content: View>: View {
    @Binding var isExpanded: Bool
    let title: String
    @ViewBuilder let content: () -> Content

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: isExpanded ? "chevron.down.dotted.2" : "chevron.right.dotted.chevron.right")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 12, height: 12)
            }
            .padding(8)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    isExpanded.toggle()
                }
            }

            if isExpanded {
                content()
                    .transition(.opacity)
            }
        }
    }
}

// MARK: - AccordionView_Previews

#Preview {
    ScrollView {
        ForEach([false, true], id: \.self) { isExpanded in
            Group {
                AccordionView(isExpanded: .constant(isExpanded),
                              title: "トレードメモ") {
                    Text("Content\nContent\nContent\nContent\nContent\nContent\nContent\nContent\nContent\nContent\nContent\nContent\nContent\nContent\nContent\nContent")
                        .frame(maxWidth: .infinity)
                }
                Divider()
            }
        }
    }
}
