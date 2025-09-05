//
//  KeyboardObserver.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/04.
//

import SwiftUI

struct KeyboardObserver: ViewModifier {
    @Binding var keyboardIsPresented: Bool

    func body(content: Content) -> some View {
        VStack {
            content

            if keyboardIsPresented {
                HStack {
                    Spacer()
                    Button {
                        UIApplication.shared.closeKeyboard()
                    } label: {
                        Text("閉じる")
                            .foregroundColor(.blue)
                            .padding()
                    }
                }
                .padding(.horizontal)
                .background(.ultraThinMaterial)
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

extension View {
    func withKeyboardToolbar(keyboardIsPresented: Binding<Bool>) -> some View {
        self.modifier(KeyboardObserver(keyboardIsPresented: keyboardIsPresented))
    }
}
