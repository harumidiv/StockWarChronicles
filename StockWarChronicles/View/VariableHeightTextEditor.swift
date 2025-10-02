//
//  VariableHeightTextEditor.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/10/02.
//

import SwiftUI

struct VariableHeightTextEditor: View {
    @Binding var text: String
    @State private var textHeight: CGFloat = 80
    private let minHeight: CGFloat = 80
    @State private var availableWidth: CGFloat = 0

    private func recalcHeight(for width: CGFloat, text: String) {
        guard width > 0 else { return }
        // Keep the previous margin compensation to preserve existing layout behavior
        let constrainedWidth = width - 40
        let newHeight = text.height(withConstrainedWidth: constrainedWidth, font: .systemFont(ofSize: 17))
        self.textHeight = max(minHeight, newHeight)
    }

    var body: some View {
        TextEditor(text: $text)
            .frame(height: textHeight)
            .padding(4)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.5))
            )
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            let w = proxy.size.width
                            if w != availableWidth {
                                availableWidth = w
                                recalcHeight(for: w, text: text)
                            }
                        }
                        .onChange(of: proxy.size) { _, newSize in
                            let w = newSize.width
                            if w != availableWidth {
                                availableWidth = w
                                recalcHeight(for: w, text: text)
                            }
                        }
                }
            )
            // Recalculate height when text changes
            .onChange(of: text) { _, newText in
                recalcHeight(for: availableWidth, text: newText)
            }
    }
}

// 文字列の高さを計算するヘルパー関数
extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        
        return boundingBox.height
    }
}

#Preview {
    VariableHeightTextEditor(text: .constant("Hello, SwiftUI!"))
}
