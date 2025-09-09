//
//  SizeLogger.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/09.
//

import SwiftUI

#if DEBUG
struct SizeLogger: ViewModifier {
    let label: String
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            print("[\(label)] サイズ: \(geometry.size)")
                        }
                        .onChange(of: geometry.size) { oldSize, newSize in
                            print("[\(label)] サイズが変更されました: \(oldSize) -> \(newSize)")
                        }
                }
            )
    }
}

extension View {
    
    /// 対象のサイズを計算してログに吐き出す
    /// - Parameter label: ログ識別用のlabel
    /// - Returns: View
    func debugSizeLogger(label: String) -> some View {
        self.modifier(SizeLogger(label: label))
    }
}

#endif
