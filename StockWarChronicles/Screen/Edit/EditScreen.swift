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
    @State private var amountText: String = ""
    @State private var sharesText: String = ""
    @State private var reason: String = ""
    @State private var selectedTags: [CategoryTag] = []
    @State private var sales: [StockTradeInfo] = []
    
    @State private var keyboardIsPresented: Bool = false
    @State private var showOversoldAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    StockFormView(
                        code: $code,
                        market: $market,
                        name: $name,
                        date: $date,
                        amountText: $amountText,
                        sharesText: $sharesText,
                        reason: $reason,
                        selectedTags: $selectedTags
                    )
                    
                    if !sales.isEmpty {
                        StockSellEditView(sales: $sales)
                    }
                }
                
                if keyboardIsPresented {
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                if record.isOversold {
                                    showOversoldAlert.toggle()
                                } else {
                                    saveChanges()
                                }
                            } label: {
                                Label("保存", systemImage: "square.and.arrow.down")
                                    .foregroundColor(.blue)
                                    .padding()
                                
                            }
                        }
                        .padding(.horizontal)
                        .background(.ultraThinMaterial)
                        
                    }
                    .background(Color.clear)
                }
                
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                keyboardIsPresented = true
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                keyboardIsPresented = false
            }
            
            .navigationTitle("編集")
            .toolbar {
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                
                ToolbarSpacer(.flexible, placement: .bottomBar)
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        if record.isOversold {
                            showOversoldAlert.toggle()
                        } else {
                            saveChanges()
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(.blue)
                    }
                }
            }
            .alert("株数に不整合があります", isPresented: $showOversoldAlert) {
                Button("閉じる", role: .cancel) { }
            } message: {
                Text("売却株数が購入株数を超えています。内容を修正してください。")
            }
        }
        .onAppear {
            code = record.code
            market = record.market
            name = record.name
            date = record.purchase.date
            amountText = String(record.purchase.amount)
            sharesText = String(record.purchase.shares)
            reason = record.purchase.reason
            selectedTags = record.tags.map { .init(name: $0.name, color: $0.color) }
            sales = record.sales
        }
    }
    
    private func saveChanges() {
        record.code = code
        record.market = market
        record.name = name
        record.purchase.date = date
        record.purchase.amount = Double(amountText) ?? 0
        record.purchase.shares = Int(sharesText) ?? 0
        record.purchase.reason = reason
        record.tags = selectedTags.map { .init(name: $0.name, color: $0.color) }
        record.sales = sales
        
        try? context.save()
        dismiss()
    }
}

struct StockSellEditView: View {
    @Binding var sales: [StockTradeInfo]
    
    var body: some View {
        Section(header: Text("売却")) {
            ForEach($sales) { $sale in
                DatePicker("売却日", selection: $sale.date, displayedComponents: .date)
                
                HStack {
                    TextField("購入額", value: $sale.amount, format: .number)
                        .keyboardType(.numberPad)
                    Text("円")
                    
                    TextField("株数", value: $sale.shares, format: .number)
                        .keyboardType(.numberPad)
                    Text("株")
                }
                
                
                VStack {
                    HStack {
                        Text("売却メモ")
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


#Preview {
    EditScreen(record: StockRecord.mockRecords.first!)
}
