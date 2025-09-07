//
//  StockFormView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/01.
//

import SwiftUI
import SwiftData

struct StockFormView: View {
    @Binding var code: String
    @Binding var market: Market
    @Binding var name: String
    @Binding var date: Date
    @Binding var position: Position
    @Binding var amount: Double
    @Binding var shares: Int
    @Binding var emotion: Emotion
    @Binding var reason: String
    @Binding var selectedTags: [CategoryTag]
    
    var body: some View {
        Section(header: Text("銘柄情報")) {
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
        
        Section(header: Text("取引情報")) {
            HStack {
                Picker("ポジション", selection: $position) {
                    ForEach(Position.allCases) { value in
                        Text(value.rawValue)
                            .tag(value)
                    }
                }
                .pickerStyle(.segmented)
            }
            Picker("感情", selection: $emotion) {
                ForEach(PurchaseEmotions.allCases) { emotion in
                    Text(emotion.rawValue + emotion.name)
                        .tag(Emotion.purchase(emotion))
                }
            }
            DatePicker("日付", selection: $date, displayedComponents: .date)
            HStack {
                TextField("金額", value: $amount, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Text("円")
                    .padding(.trailing, 8)
                TextField("株数", value: $shares, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
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
            TagSelectionView(selectedTags: $selectedTags)
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
            position: .constant(.buy),
            amount: .constant(200000),
            shares: .constant(100),
            emotion: .constant(Emotion.purchase(.random)
                              ),
            reason: .constant("長期投資のため"),
            selectedTags: .constant([
                CategoryTag(name: "自動車", color: .blue),
                CategoryTag(name: "大型株", color: .green)
            ])
        )
    }
}
