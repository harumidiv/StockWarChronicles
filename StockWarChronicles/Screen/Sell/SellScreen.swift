//
//  SellScreen.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/19.
//

import SwiftUI
import SwiftData

struct SellScreen: View {
    enum SellUnit {
        case hundreds
        case ones
    }
    
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var record: StockRecord
    
    @State private var sellDate = Date.fromToday()
    @State private var amount = ""
    @State private var shares = 0
    @State private var sellUnit: SellUnit = .hundreds
    @State private var reason = ""
    @State private var emotion: Emotion = .sales(.normal)
    
    @State private var keyboardIsPresented: Bool = false
    @State private var showDateAlert: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text(record.code + " " + record.name)) {
                        Picker("感情", selection: $emotion) {
                            ForEach(SalesEmotions.allCases) { emotion in
                                Text(emotion.rawValue + emotion.name)
                                    .tag(Emotion.sales(emotion))
                            }
                        }
                        DatePicker("売却日", selection: $sellDate, displayedComponents: .date)
                        
                        HStack {
                            TextField("売却額", text: $amount)
                                .keyboardType(.decimalPad)
                            Text("円")
                        }
                        
                        HStack {
                            Picker("株数", selection: $shares) {
                                switch sellUnit {
                                case .hundreds:
                                    ForEach(Array(stride(from: 100, through: record.remainingShares, by: 100)), id: \.self) { num in
                                        Text("\(num)").tag(num)
                                    }
                                case .ones:
                                    ForEach(Array(stride(from: 1, through: record.remainingShares, by: 1)), id: \.self) { num in
                                        Text("\(num)").tag(num)
                                    }
                                }
                            }
                            .pickerStyle(.menu)
                            
                            Button(action: {
                                withAnimation {
                                    switch sellUnit {
                                    case .hundreds:
                                        sellUnit = .ones
                                        shares = 1
                                    case .ones:
                                        sellUnit = .hundreds
                                        shares = 100
                                    }
                                }
                            }) {
                                Image(systemName: "arrow.2.circlepath")
                                    .font(.title3)
                            }
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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("dismiss", systemImage: "xmark") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button (action: {
                        if Calendar.current.startOfDay(for: record.purchase.date) > Calendar.current.startOfDay(for: sellDate) {
                            showDateAlert.toggle()
                        } else {
                            saveSell()
                        }
                        
                        
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
        .withKeyboardToolbar(keyboardIsPresented: $keyboardIsPresented)
        .onAppear {
            shares = record.remainingShares
            if shares < 100 {
                sellUnit = .ones
            }
        }
        .alert("売却日が購入日以前に設定されています", isPresented: $showDateAlert) {
            Button("閉じる", role: .cancel) { }
        } message: {
            Text("内容を修正してください。")
        }
        
    }
 
    private func saveSell() {
        guard let amount = Double(amount) else { return }
        
        let sellInfo = StockTradeInfo(amount: amount, shares: shares, date: sellDate, emotion: emotion, reason: reason)
        record.sales.append(sellInfo)
        
        try? context.save()
        dismiss()
    }
}

#Preview {
    SellScreen(record: StockRecord(code: "350A", market: .tokyo, name: "デジタルグリッド", purchase: .init(amount: 5100, shares: 100, date: Date(), emotion: Emotion.sales(.random), reason: "ストック売り上げ")))
}
