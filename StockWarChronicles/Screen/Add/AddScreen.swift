//
//  AddScreen.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/19.
//

import SwiftUI
import SwiftData

struct AddScreen: View {
    @Environment(\.modelContext) private var context
    @Binding var showAddStockView: Bool
    
    @State private var code = ""
    @State private var market: Market = .tokyo
    @State private var position: Position = .buy
    @State private var name = ""
    @State private var date = Date.fromToday()
    @State private var amountText = ""
    @State private var sharesText = ""
    @State private var emotion: Emotion = Emotion.purchase(.normal)
    @State private var reason = ""
    @State private var selectedTags: [Tag] = []
    
    @State private var keyboardIsPresented: Bool = false
    @FocusState private var focusedField: StockFormFocusFields?
    @State private var isNeedNextBotton: Bool = false
    
    var amount: Double {
        Double(amountText) ?? 0
    }
    
    var shares: Int {
        Int(sharesText) ?? 0
    }
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollViewReader { proxy in
                    Form {
                        StockFormView(
                            code: $code, market: $market, name: $name,
                            date: $date, position: $position, amountText: $amountText,
                            sharesText: $sharesText, emotion: $emotion,
                            reason: $reason, selectedTags: $selectedTags, focusedField: $focusedField
                        )
                    }
                    .onChange(of: focusedField) {
                        if let focusedField = focusedField {
                            withAnimation {
                                proxy.scrollTo(focusedField, anchor: .top)
                            }
                        }
                    }
                }
            }
            .navigationTitle("追加")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("dismiss", systemImage: "xmark") {
                        showAddStockView.toggle()
                    }
                }
                
                let isDisable = code.isEmpty || amount == 0 || shares == 0
                ToolbarItem(placement: .topBarTrailing) {
                    Button (
                        action: {
                            saveAction()
                        },
                        label: {
                            HStack {
                                Image(systemName: "externaldrive")
                                Text("保存")
                            }
                            .padding(.horizontal)
                            .opacity(isDisable ? 0.5 : 1.0)
                        })
                    .disabled(isDisable)
                }
            }
        }
        .withKeyboardToolbar(keyboardIsPresented: $keyboardIsPresented, isNeedNextBotton: $isNeedNextBotton) {
            focusedField = focusedField?.next()
        }
        .onChange(of: focusedField) {
            switch focusedField {
            case .code, .amount, .shares:
                isNeedNextBotton = true
            case .name, .memo, .tag:
                isNeedNextBotton = false
            case nil:
                isNeedNextBotton = false
            }
        }
    }
    
    private func saveAction() {
        let tradeInfo = StockTradeInfo(
            amount: Double(amountText) ?? 0,
            shares: Int(sharesText) ?? 0,
            date: date, emotion: emotion, reason: reason
        )
        let stockRecord = StockRecord(
            code: code, market: market, name: name, position: position,
            purchase: tradeInfo, sales: [],
            tags: selectedTags
        )
        context.insert(stockRecord)
        try? context.save()
        showAddStockView.toggle()
    }
}

#Preview {
    AddScreen(showAddStockView: .constant(true))
}

