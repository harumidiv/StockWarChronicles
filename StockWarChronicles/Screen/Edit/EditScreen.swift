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
    @State private var amountText: String = ""
    @State private var sharesText: String = ""
    @State private var emotion: Emotion = .purchase(.normal)
    @State private var reason: String = ""
    @State private var selectedTags: [Tag] = []
    @State private var sales: [StockTradeInfo] = []
    
    @State private var showOversoldAlert = false
    @State private var showDeleteAlert: Bool = false
    @State private var showSaveConfirmAlert: Bool = false
    
    @State private var keyboardIsPresented: Bool = false
    @FocusState private var focusedField: StockFormFocusFields?
    
    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                Form {
                    StockFormView(
                        code: $code,
                        market: $market,
                        name: $name,
                        date: $date,
                        position: $position,
                        amountText: $amountText,
                        sharesText: $sharesText,
                        emotion: $emotion,
                        reason: $reason,
                        selectedTags: $selectedTags,
                            focusedField: $focusedField
                    )
                    
                    if !sales.isEmpty {
                        StockSellEditView(sales: $sales)
                    }
                }
                .onChange(of: focusedField) {
                    if let focusedField = focusedField {
                        withAnimation {
                            proxy.scrollTo(focusedField.scrollAnchor, anchor: .top)
                        }
                    }
                }
                .withKeyboardToolbar(
                    keyboardIsPresented: $keyboardIsPresented,
                    focusedField: $focusedField,
                    scrollProxy: proxy
                )
            }
            .navigationTitle("編集")
                .toolbar {
                
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            if code != record.code ||
                                market != record.market ||
                                name != record.name ||
                                date != record.purchase.date ||
                                position != record.position ||
                                amountText != String(record.purchase.amount) ||
                                sharesText != String(record.purchase.shares) ||
                                emotion != record.purchase.emotion ||
                                reason != record.purchase.reason ||
                                Set(selectedTags.map { $0.name }) != Set(record.tags.map { $0.name }) ||
                                sales.count != record.sales.count {
                                showSaveConfirmAlert.toggle()
                            } else {
                                dismiss()
                            }
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                
                    ToolbarItem(placement: .topBarTrailing) {
                        Button (
                            action: {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                /// 売り枚数の方が方が大きくなっていないか
                                let totalSold = sales.map(\.shares).reduce(0, +)
                                let isOversold =  totalSold > Int(sharesText) ?? 0
                            
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
                                .padding(.horizontal)
                            
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
                .alert("変更が保存されていません", isPresented: $showSaveConfirmAlert) {
                    Button("破棄", role: .destructive) {
                        dismiss()
                    }
                    Button("キャンセル", role: .cancel) { }
                } message: {
                    Text("保存せずに閉じますか？")
                }
        }
        .onAppear {
            code = record.code
            market = record.market
            name = record.name
            date = record.purchase.date
            position = record.position
            amountText = String(record.purchase.amount)
            sharesText = String(record.purchase.shares)
            emotion = record.purchase.emotion
            reason = record.purchase.reason
            selectedTags = record.tags.map { .init(name: $0.name, color: $0.color) }
            // 🌾SwiftDataに保存している関係でclassで作っていて参照型なのでcopyする
            sales = record.sales.map { $0.copy() as! StockTradeInfo }.sorted(by: { $0.date > $1.date })
        }
    }
    
    private func saveChanges() {
        record.code = code
        record.market = market
        record.name = name
        record.position = position
        record.purchase.date = date
        record.purchase.amount = Double(amountText) ?? 0
        record.purchase.shares = Int(sharesText) ?? 0
        record.purchase.emotion = emotion
        record.purchase.reason = reason
        record.tags = selectedTags.map { .init(name: $0.name, color: $0.color) }
        record.sales = sales
        
        try? context.save()
        dismiss()
    }
    
    private func deleteHistory() {
        // 🌾削除前に編集されていると同期が取れずクラッシュするので反映させる
        saveChanges()
        
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
    @State private var calendarId: UUID = UUID()
    var body: some View {
        ForEach($sales) { $sale in
            Section(header: Text("売却: \(sale.date.formatted(as: .yyyyMMdd))")) {
                VStack {
                    datePickerView(for: $sale)
                        .padding(.bottom)
                    amountAndSharesView(for: $sale)
                    emotionPicker(for: $sale)
                    memoView(for: $sale)
                        .padding(.bottom)
                    deleteButton(for: $sale)
                }
            }
        }
    }
}

private extension StockSellEditView {
    
    func deleteButton(for sale: Binding<StockTradeInfo>) -> some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            if let index = sales.firstIndex(where: { $0.id == sale.id }) {
                sales.remove(at: index)
            }
        }) {
            Text("削除")
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 240, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red)
                )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
    
    // 日付選択
    func datePickerView(for sale: Binding<StockTradeInfo>) -> some View {
        VStack {
            DatePickerAccordionView(date: sale.date)
            Divider().background(.separator)
        }
    }
    
    // 購入額と株数
    func amountAndSharesView(for sale: Binding<StockTradeInfo>) -> some View {
        HStack {
            VStack {
                HStack {
                    TextField("購入額", value: sale.amount, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                    Text("円")
                }
                Divider().background(.separator).padding(.bottom)
            }
            VStack {
                HStack {
                    TextField("株数", value: sale.shares, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                    Text("株")
                }
                Divider().background(.separator).padding(.bottom)
            }
            .padding(.leading)
        }
    }
    
    // メモ入力欄
    func memoView(for sale: Binding<StockTradeInfo>) -> some View {
        VStack {
            HStack {
                Text("メモ")
                    .font(.caption2)
                    .foregroundColor(.gray)
                Spacer()
            }
            VariableHeightTextEditor(text: sale.reason)
        }
    }
    
    // 感情 Picker
    func emotionPicker(for sale: Binding<StockTradeInfo>) -> some View {
        VStack {
            Picker("感情", selection: sale.emotion) {
                ForEach(SalesEmotions.allCases) { emotion in
                    Text(emotion.rawValue + emotion.name)
                        .tag(Emotion.sales(emotion))
                }
            }
            .tint(.primary)
            .pickerStyle(.menu)
            .sensoryFeedback(.selection, trigger: sale.emotion.wrappedValue)
            Divider()
                .background(.separator)
                .padding(.bottom)
        }
    }
}

#if DEBUG
#Preview {
    EditScreen(record: StockRecord.mockRecords.first!)
}
#endif
