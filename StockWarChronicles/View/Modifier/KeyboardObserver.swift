//
//  KeyboardObserver.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/04.
//

import SwiftUI
import UIKit

/// キーボードの上に重ねて表示するツールバー
/// 左に前後のフィールドへ移動するボタン、右にキーボードを閉じるボタンを配置する
private struct KeyboardToolbar: View {
    let isFieldNavigationEnabled: Bool
    let canGoPrevious: Bool
    let canGoNext: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onDone: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            if isFieldNavigationEnabled {
                button(systemName: "chevron.up", isEnabled: canGoPrevious, action: onPrevious)
                button(systemName: "chevron.down", isEnabled: canGoNext, action: onNext)
            }

            Spacer()

            button(systemName: "checkmark", isEnabled: true, action: onDone)
        }
        .padding(.horizontal, 8)
        .glassEffect(.regular.interactive())
        // キーボードとフォームの間に余白を作ってバーを浮かせる
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func button(systemName: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(isEnabled ? Color.primary : Color.secondary.opacity(0.4))
                .frame(width: 56, height: 44)
                .contentShape(Rectangle())
        }
        .disabled(!isEnabled)
    }
}

/// キーボードを閉じるボタンのみを表示するモディファイア
struct KeyboardObserver: ViewModifier {
    @Binding var keyboardIsPresented: Bool

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            content

            if keyboardIsPresented {
                KeyboardToolbar(
                    isFieldNavigationEnabled: false,
                    canGoPrevious: false,
                    canGoNext: false,
                    onPrevious: {},
                    onNext: {},
                    onDone: { UIApplication.shared.closeKeyboard() }
                )
            }
        }
        .observeKeyboardPresence($keyboardIsPresented)
    }
}

/// 株フォームのフィールド間を上下ボタンで移動できるモディファイア
struct StockFormKeyboardObserver: ViewModifier {
    @Binding var keyboardIsPresented: Bool
    @FocusState.Binding var focusedField: StockFormFocusFields?
    let scrollProxy: ScrollViewProxy

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            content

            if keyboardIsPresented {
                KeyboardToolbar(
                    isFieldNavigationEnabled: true,
                    canGoPrevious: focusedField?.previous() != nil,
                    canGoNext: focusedField?.next() != nil,
                    onPrevious: { move(to: focusedField?.previous()) },
                    onNext: { move(to: focusedField?.next()) },
                    onDone: {
                        focusedField = nil
                        UIApplication.shared.closeKeyboard()
                    }
                )
            }
        }
        .observeKeyboardPresence($keyboardIsPresented)
    }

    /// Formの行は画面外だと生成されず`focused`も登録されないため、
    /// 先に移動先までスクロールして行を作ってからフォーカスを移す
    private func move(to field: StockFormFocusFields?) {
        guard let field else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            scrollProxy.scrollTo(field.scrollAnchor, anchor: .top)
        } completion: {
            focusedField = field
        }
    }
}

private extension View {
    func observeKeyboardPresence(_ keyboardIsPresented: Binding<Bool>) -> some View {
        self
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                keyboardIsPresented.wrappedValue = true
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                keyboardIsPresented.wrappedValue = false
            }
    }
}

// ビューモディファイアを使いやすくするExtension
extension View {
    func withKeyboardToolbar(keyboardIsPresented: Binding<Bool>) -> some View {
        self.modifier(KeyboardObserver(keyboardIsPresented: keyboardIsPresented))
    }

    func withKeyboardToolbar(
        keyboardIsPresented: Binding<Bool>,
        focusedField: FocusState<StockFormFocusFields?>.Binding,
        scrollProxy: ScrollViewProxy
    ) -> some View {
        self.modifier(
            StockFormKeyboardObserver(
                keyboardIsPresented: keyboardIsPresented,
                focusedField: focusedField,
                scrollProxy: scrollProxy
            )
        )
    }
}
