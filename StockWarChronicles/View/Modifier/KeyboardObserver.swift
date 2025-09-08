//
//  KeyboardObserver.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/04.
//

import SwiftUI
import UIKit

struct KeyboardObserver: ViewModifier {
    @Binding var keyboardIsPresented: Bool
    let isNeedNextBotton: Bool
    let onNext: () -> Void

    // イニシャライザでハンドラを受け取る
    init(keyboardIsPresented: Binding<Bool>, isNeedNextBotton: Bool, onNext: @escaping () -> Void,) {
        self._keyboardIsPresented = keyboardIsPresented
        self.isNeedNextBotton = isNeedNextBotton
        self.onNext = onNext
    }
    
    func body(content: Content) -> some View {
        VStack {
            content
            
            if keyboardIsPresented {
                HStack {
                    // 「閉じる」ボタン
                    Button(action: {
                        UIApplication.shared.closeKeyboard()
                    }) {
                        Text("閉じる")
                            .padding()
                            .foregroundColor(.green)
                    }
                    
                    
                    Spacer()
                    
                    if isNeedNextBotton {
                        Button(action: {
                            onNext()
                        }) {
                            Text("次へ")
                                .padding()
                                .foregroundColor(.green)
                        }
                        
                    }
                }
                
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            keyboardIsPresented = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardIsPresented = false
        }
    }
}

// ビューモディファイアを使いやすくするExtension
extension View {
    func withKeyboardToolbar(
        keyboardIsPresented: Binding<Bool>,
        isNeedNextBotton: Bool = false,
        onNext: @escaping () -> Void
    ) -> some View {
        self.modifier(
            KeyboardObserver(
                keyboardIsPresented: keyboardIsPresented,
                isNeedNextBotton: isNeedNextBotton,
                onNext: onNext,
            )
        )
    }
}
