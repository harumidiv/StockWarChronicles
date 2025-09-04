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
    @State private var name = ""
    @State private var date = Date.fromToday()
    @State private var amountText = ""
    @State private var sharesText = ""
    @State private var reason = ""
    @State private var selectedTags: [CategoryTag] = []
    
    var amount: Double {
        Double(amountText) ?? 0
    }
    
    var shares: Int {
        Int(sharesText) ?? 0
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    StockFormView(
                        code: $code, market: $market, name: $name,
                        date: $date, amountText: $amountText,
                        sharesText: $sharesText, reason: $reason,
                        selectedTags: $selectedTags
                    )
                }
            }
            .navigationTitle("追加")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("dismiss", systemImage: "xmark") {
                        showAddStockView.toggle()
                    }
                }
                
                let isDisable = name.isEmpty || code.isEmpty || amount == 0 || shares == 0 || reason.isEmpty
                ToolbarItem(placement: .topBarTrailing) {
                    Button (
                        action: {
                            saveAction()
                        },
                        label: {
                        HStack {
                            Image(systemName: "externaldrive")
                            Text("追加")
                        }
                    })
                    .disabled(isDisable)
                }
            }
        }
        .withKeyboardToolbar()
    }
    
    private func saveAction() {
        let tradeInfo = StockTradeInfo(
            amount: Double(amountText) ?? 0,
            shares: Int(sharesText) ?? 0,
            date: date, reason: reason
        )
        let stockRecord = StockRecord(
            code: code, market: market, name: name,
            purchase: tradeInfo, sales: [],
            tags: selectedTags.map { Tag(categoryTag: $0) }
        )
        context.insert(stockRecord)
        try? context.save()
        showAddStockView.toggle()
    }
}

#Preview {
    AddScreen(showAddStockView: .constant(true))
}
