//
//  ChipsView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/01.
//

import SwiftUI

struct ChipsView<Content: View>: View {
    var spacing: CGFloat = 6
    var animation: Animation = .easeInOut(duration: 0.2)
    
    var tags: [Tag]
    @ViewBuilder var content: (Tag) -> Content
    var onTap: ((Tag) -> Void)? = nil
    
    var body: some View {
        CustomClipLayout(spacing: spacing) {
            ForEach(tags, id: \.self) { tag in
                Button(action: {
                    onTap?(tag)
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }) {
                    content(tag)
                }
                
            }
        }
    }
}

fileprivate struct CustomClipLayout: Layout {
    var spacing: CGFloat
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        return .init(width: width, height: maxHeight(proposal: proposal, subviews: subviews))
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var origin = bounds.origin
        
        for subview in subviews {
            let fitSize = subview.sizeThatFits(proposal)
            
            if origin.x + fitSize.width > bounds.maxX {
                origin.x = bounds.minX
                origin.y += fitSize.height + spacing
                
                subview.place(at: origin, proposal: proposal)
                origin.x += fitSize.width + spacing
            } else {
                subview.place(at: origin, proposal: proposal)
                origin.x += fitSize.width + spacing
            }
        }
    }
    
    private func maxHeight(proposal: ProposedViewSize, subviews: Subviews) -> CGFloat {
        var origin: CGPoint = .zero
        
        for subview in subviews {
            let fitSize = subview.sizeThatFits(proposal)
            
            if origin.x + fitSize.width > (proposal.width ?? 0) {
                origin.x = 0
                origin.y += fitSize.height + spacing
                origin.x += fitSize.width + spacing
            } else {
                origin.x += fitSize.width + spacing
            }
            
            if subview == subviews.last {
                origin.y += fitSize.height
            }
        }
        
        return origin.y
    }
}

#Preview {
    ChipsView(tags: [.init(name: "タグ", color: .red), .init(name: "タグ2", color: .blue), .init(name: "名前の長いタグ名前の長いタグ名前の長いタグ名前の長いタグ名前の長いタグ", color: .green)], content: {
        tag in
        
        TagView(name: tag.name, color: tag.color)
    })
    .padding()
}
