//
//  AddStockView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/19.
//

import SwiftUI

struct AddStockView: View {
    @State private var code = ""
    @State private var name = ""
    @State private var purchaseDate = Date()
    @State private var purchaseAmountText = ""
    @State private var sharesText = ""
    @State private var tags: [Tag] = [
        Tag(name: "AAA", color: .red),
        Tag(name: "BBB", color: .blue),
        Tag(name: "CCC", color: .green)
    ]
    @State private var newTagName = ""
    @State private var newTagColor: Color = .gray
    @State private var reason = ""
    
    var purchaseAmount: Double {
        Double(purchaseAmountText) ?? 0
    }
    var shares: Int {
        Int(purchaseAmountText) ?? 0
    }

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section {
                        TextField("コード", text: $code)
                        TextField("名前", text: $name)

                        DatePicker("購入日", selection: $purchaseDate, displayedComponents: .date)

                        HStack {
                            TextField("購入額", text: $purchaseAmountText)
                                .keyboardType(.numberPad)
                            Text("円")
                        }

                        TextField("株数", text: $sharesText)
                            .keyboardType(.numberPad)
                    }

                    Section(header: Text("タグ")) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(tags) { tag in
                                    Text(tag.name)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(tag.color.opacity(0.3))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        
                        HStack {
                            TextField("新しいタグ", text: $newTagName)

                            ColorPicker("", selection: $newTagColor)
                                .labelsHidden()
                                .frame(width: 40, height: 40)

                            Button(action: {
                                if !newTagName.isEmpty {
                                    tags.append(Tag(name: newTagName, color: newTagColor))
                                    newTagName = ""
                                    newTagColor = .gray
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                            }
                        }
                    }

                    Section(header: Text("購入理由")) {
                        TextEditor(text: $reason)
                            .frame(height: 100)
                            .padding(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5))
                            )
                    }
                }

                Button(action: {
                    // TODO: 必須項目が欠けている場合に警告を出す
                    // TODO: SwiftDataに保存
                    let tradeInfo = StockTradeInfo(amount: purchaseAmount, shares: shares, date: purchaseDate, reason: reason)
                    StockRecord(code: code, name: name, purchase: tradeInfo, sales: [], tags: tags)
                }) {
                    Text("追加")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("追加")
        }
    }
}


#Preview {
    AddStockView()
}

