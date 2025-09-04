//
//  SellScreen.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/19.
//

import SwiftUI
import SwiftData


struct SellScreen: View {
    @Environment(\.modelContext) private var context
    
    @Bindable var record: StockRecord
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var sellDate = Date.fromToday()
    @State private var amount = ""
    @State private var shares = 0
    @State private var reason = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section(header: Text(record.code + " " + record.name)) {
                        DatePicker("売却日", selection: $sellDate, displayedComponents: .date)
                        
                        HStack {
                            TextField("売却額", text: $amount)
                                .keyboardType(.decimalPad)
                            Text("円")
                        }
                        
                        HStack {
                            Picker("株数", selection: $shares) {
                                ForEach(Array(stride(from: 100, through: record.remainingShares, by: 100)), id: \.self) { num in
                                    Text("\(num)").tag(num)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        VStack {
                            HStack {
                                Text("メモ")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            TextEditor(text: $reason)
                                .frame(height: 100)
                                .padding(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.5))
                                )
                        }
                    }
                }
            }
            .navigationTitle("売却")
        }
        .withKeyboardToolbar()
        .onAppear {
            shares = record.remainingShares
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button (action: {
                    saveSell()
                    
                }, label: {
                    HStack {
                        Image(systemName: "externaldrive")
                        Text("保存")
                    }
                })
                .disabled(amount.isEmpty)
            }
        }
    }
    
    private func saveSell() {
        guard let amount = Double(amount) else { return }
        
        let sellInfo = StockTradeInfo(amount: amount, shares: shares, date: sellDate, reason: reason)
        record.sales.append(sellInfo)
        
        try? context.save()
        dismiss()
    }
}

#Preview {
    SellScreen(record: StockRecord(code: "350A", market: .tokyo, name: "デジタルグリッド", purchase: .init(amount: 5100, shares: 100, date: Date(), reason: "ストック売り上げ")))
}
