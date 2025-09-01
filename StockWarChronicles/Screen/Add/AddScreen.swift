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
    @State private var date = Date()
    @State private var amountText = ""
    @State private var sharesText = ""
    @State private var reason = ""
    
    @State private var selectedTags: [CategoryTag] = []
    
    @State private var isDeleteConfirmAlertPresented: Bool = false
    @State private var selectedDeleteTag: CategoryTag?
    
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
                    Section {
                        HStack {
                            TextField("銘柄コード", text: $code)
                            Picker("", selection: $market) {
                                ForEach(Market.allCases) { market in
                                    Text(market.rawValue)
                                        .tag(market)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        TextField("銘柄名", text: $name)
                        
                        DatePicker("購入日", selection: $date, displayedComponents: .date)
                        
                        HStack {
                            TextField("購入額", text: $amountText)
                                .keyboardType(.numberPad)
                            Text("円")
                            
                            TextField("株数", text: $sharesText)
                                .keyboardType(.numberPad)
                            Text("株")
                        }
                    }
                    
                    Section(header: Text("購入理由")) {
                        TextEditor(text: $reason)
                            .frame(height: 80)
                            .padding(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5))
                            )
                    }
                    
                    Section(header: Text("タグ")) {
                        TagSelectionView(selectedTags: $selectedTags) { tag in
                            isDeleteConfirmAlertPresented.toggle()
                            selectedDeleteTag = tag
                        }
                    }
                }
                
                let isDisable = name.isEmpty || code.isEmpty || amount == 0 || shares == 0 || reason.isEmpty
                
                Button(action: {
                    let tradeInfo = StockTradeInfo(amount: amount, shares: shares, date: date, reason: reason)
                    let stockRecord = StockRecord(code: code, market: market, name: name, purchase: tradeInfo, sales: [], tags: selectedTags.map { Tag(categoryTag: $0) })
                    context.insert(stockRecord)
                    
                        try? context.save()
                        showAddStockView.toggle()
                        }) {
                    Text("追加")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(isDisable ? Color.gray : Color.blue)
                        .cornerRadius(10)
                }
                .padding()
                .disabled(isDisable)
            }
            .navigationTitle("追加")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("close", systemImage: "xmark") {
                        showAddStockView.toggle()
                    }
                }
            }
            .alert("本当に削除しますか？", isPresented: $isDeleteConfirmAlertPresented) {
                Button("削除", role: .destructive) {
                    if let selectedDeleteTag {
                        context.delete(selectedDeleteTag)
                        try? context.save()
                    }
                }
                Button("キャンセル", role: .cancel) { selectedDeleteTag = nil }
            } message: {
                Text("このタグが既存タグに候補として表示されなくなります")
            }
        }
    }
}

#Preview {
    AddScreen(showAddStockView: .constant(true))
}
