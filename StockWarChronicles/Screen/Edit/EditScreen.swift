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
    
    @State private var keyboardIsPresented: Bool = false
    @State private var showOversoldAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
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
            .alert("不整合の警告", isPresented: $showOversoldAlert) {
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
        
        try? context.save()
        dismiss()
    }
}



#Preview {
    EditScreen(record: StockRecord.mockRecords.first!)
}
