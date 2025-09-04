//
//  StockFormView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/01.
//

import SwiftUI

struct StockFormView: View {
    @Binding var code: String
    @Binding var market: Market
    @Binding var name: String
    @Binding var date: Date
    @Binding var amountText: String
    @Binding var sharesText: String
    @Binding var reason: String
    @Binding var selectedTags: [CategoryTag]
    
    var body: some View {
        Section(header: Text("サマリー")) {
            HStack {
                TextField("銘柄コード", text: $code)
                Picker("", selection: $market) {
                    ForEach(Market.allCases) { market in
                        Text(market.rawValue).tag(market)
                    }
                }
                .pickerStyle(.menu)
            }
            TextField("銘柄名", text: $name)
        }
        
        Section(header: Text("購入")) {
            DatePicker("購入日", selection: $date, displayedComponents: .date)
            HStack {
                TextField("購入額", text: $amountText)
                    .keyboardType(.decimalPad)
                Text("円")
                TextField("株数", text: $sharesText)
                    .keyboardType(.numberPad)
                Text("株")
            }
            
            VStack {
                HStack {
                    Text("メモ")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                }
                TextEditor(text: $reason)
                    .frame(height: 80)
                    .padding(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.5))
                    )
            }
            
        }
        
        Section(header: Text("タグ")) {
            TagSelectionView(selectedTags: $selectedTags) { tag in
                // タグ削除の処理は親ビューに渡してもいい
            }
        }
    }
}

#Preview {
    Form {
        StockFormView(
            code: .constant("7203"),
            market: .constant(.tokyo),
            name: .constant("トヨタ自動車"),
            date: .constant(Date()),
            amountText: .constant("200000"),
            sharesText: .constant("100"),
            reason: .constant("長期投資のため"),
            selectedTags: .constant([
                CategoryTag(name: "自動車", color: .blue),
                CategoryTag(name: "大型株", color: .green)
            ])
        )
    }
}
