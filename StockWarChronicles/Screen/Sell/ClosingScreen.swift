//
//  ClosingScreen.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/19.
//

import SwiftUI
import SwiftData

struct ClosingScreen: View {
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
    
    @State var calendarId: UUID = UUID()
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text(record.code + " " + record.name)) {
                        VStack {
                            Picker("感情", selection: $emotion) {
                                ForEach(SalesEmotions.allCases) { emotion in
                                    Text(emotion.rawValue + emotion.name)
                                        .tag(Emotion.sales(emotion))
                                }
                            }
                            .tint(.green)
                            Divider().background(.separator)
                        }
                        
                        VStack {
                            DatePicker("日付", selection: $sellDate, displayedComponents: .date)
                                .id(calendarId)
                                .onChange(of: sellDate) {oldValue, newValue in
                                let calendar = Calendar.current
                                    let oldDateWithoutTime = calendar.component(.day, from: oldValue)
                                    let newDateWithoutTime = calendar.component(.day, from: newValue)
                                
                                if oldDateWithoutTime != newDateWithoutTime {
                                    let generator = UISelectionFeedbackGenerator()
                                    generator.selectionChanged()
                                    calendarId = UUID()
                                }
                            }
                            Divider().background(.separator)
                        }
                        
                        VStack {
                            HStack {
                                TextField("金額", text: $amount)
                                    .keyboardType(.decimalPad)
                                Text("円")
                            }
                            Divider().background(.separator)
                        }
                        
                        VStack {
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
                                .tint(.green)
                                
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
                                    Image(systemName: "arrow.up.arrow.down")
                                        .font(.title3)
                                }
                                .tint(.green)
                            }
                            Divider().background(.separator)
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
                    .listRowSeparator(.hidden)
                }
            }
            .navigationTitle("手仕舞い")
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
                        .padding(.horizontal)
                        .opacity(amount.isEmpty ? 0.5 : 1.0)
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
    ClosingScreen(record: StockRecord(code: "350A", market: .tokyo, name: "デジタルグリッド", position: .buy, purchase: .init(amount: 5100, shares: 100, date: Date(), emotion: Emotion.sales(.random), reason: "ストック売り上げ")))
}
