//
//  EditScreen.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/01.
//

import SwiftUI
import SwiftData

struct EditScreen: View {
    @Bindable var record: StockRecord
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @State private var code: String = ""
    @State private var market: Market = .tokyo
    @State private var name: String = ""
    @State private var date: Date = Date()
    @State private var position: Position = .buy
    @State private var amount: Double = 0.0
    @State private var shares: Int = 0
    @State private var emotion: Emotion = .purchase(.normal)
    @State private var reason: String = ""
    @State private var selectedTags: [CategoryTag] = []
    @State private var sales: [StockTradeInfo] = []
    
    @State private var showOversoldAlert = false
    @State private var showDeleteAlert: Bool = false
    
    @State private var keyboardIsPresented: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    StockFormView(
                        code: $code,
                        market: $market,
                        name: $name,
                        date: $date,
                        position: $position,
                        amount: $amount,
                        shares: $shares,
                        emotion: $emotion,
                        reason: $reason,
                        selectedTags: $selectedTags
                    )
                    
                    if !sales.isEmpty {
                        StockSellEditView(sales: $sales)
                    }
                }
            }
            .navigationTitle("編集")
            .toolbar {
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button (
                        action: {
                            /// 売り枚数の方が方が大きくなっていないか
                            let totalSold = sales.map(\.shares).reduce(0, +)
                            let isOversold =  totalSold > shares
                            
                            let totalSoldDate = sales.map(\.date)
                            let calendar = Calendar.current
                            let startOfDate = calendar.startOfDay(for: date)

                            let isInvalidDate = totalSoldDate.first(where: {
                                let startOfSoldDate = calendar.startOfDay(for: $0)
                                return startOfSoldDate < startOfDate
                            }) != nil
                            
                            if isOversold || isInvalidDate {
                                showOversoldAlert.toggle()
                            } else {
                                saveChanges()
                            }
                            
                        },
                        label: {
                            HStack {
                                Image(systemName: "externaldrive")
                                Text("保存")
                            }
                        })
                }
                
                if !keyboardIsPresented {
                    ToolbarSpacer(.flexible, placement: .bottomBar)
                    ToolbarItem(placement: .bottomBar) {
                        Button("delete", systemImage: "trash") {
                            showDeleteAlert = true
                        }
                        .tint(.red)
                    }
                }
            }
            .alert("株数か日付に不備があります", isPresented: $showOversoldAlert) {
                Button("閉じる", role: .cancel) { }
            } message: {
                Text("内容を修正してください。")
            }
            .alert("本当に削除しますか？", isPresented: $showDeleteAlert) {
                Button("削除", role: .destructive) {
                    deleteHistory()
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("この株取引データは完全に削除されます。")
            }
        }
        .withKeyboardToolbar(keyboardIsPresented: $keyboardIsPresented)
        .onAppear {
            code = record.code
            market = record.market
            name = record.name
            date = record.purchase.date
            position = record.position
            amount = record.purchase.amount
            shares = record.purchase.shares
            emotion = record.purchase.emotion
            reason = record.purchase.reason
            selectedTags = record.tags.map { .init(name: $0.name, color: $0.color) }
            // 🌾SwiftDataに保存している関係でclassで作っていて参照型なのでcopyする
            sales = record.sales.map { $0.copy() as! StockTradeInfo }
        }
    }
    
    private func saveChanges() {
        record.code = code
        record.market = market
        record.name = name
        record.position = position
        record.purchase.date = date
        record.purchase.amount = amount
        record.purchase.shares = shares
        record.purchase.emotion = emotion
        record.purchase.reason = reason
        record.tags = selectedTags.map { .init(name: $0.name, color: $0.color) }
        record.sales = sales
        
        try? context.save()
        dismiss()
    }
    
    private func deleteHistory() {
        context.delete(record)
        do {
            try context.save()
        } catch {
            print("削除エラー: \(error)")
        }
        
        dismiss()
    }
}

struct StockSellEditView: View {
    @Binding var sales: [StockTradeInfo]
    var body: some View {
        Section(header: Text("売却")) {
            ForEach($sales) { $sale in
                VStack {
                    HStack(alignment: .top) {
                        Button(action: {
                            if let index = $sales.wrappedValue.firstIndex(where: { $0.id == sale.id }) {
                                $sales.wrappedValue.remove(at: index)
                            }
                        }, label: {
                            Image(systemName: "xmark.app")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.red)
                        })
                        .buttonStyle(.plain)
                        DatePicker("売却日", selection: $sale.date, displayedComponents: .date)
                    }
                    
                    Picker("感情", selection: $sale.emotion) {
                        ForEach(SalesEmotions.allCases) { emotion in
                            Text(emotion.rawValue + emotion.name)
                                .tag(Emotion.sales(emotion))
                        }
                    }
                    
                    HStack {
                        TextField("購入額", value: $sale.amount, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("円")
                        
                        TextField("株数", value: $sale.shares, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("株")
                    }
                    
                    VStack {
                        HStack {
                            Text("メモ")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        TextEditor(text: $sale.reason)
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
    }
}


#Preview {
    EditScreen(record: StockRecord.mockRecords.first!)
}
