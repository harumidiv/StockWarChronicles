//
//  AddScreen.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/19.
//

import SwiftUI
import SwiftData

enum Emotion: Codable, Hashable {
    case purchase(PurchaseEmotions)
    case sales(SalesEmotions)
    
    var emoji: String {
        switch self {
        case .purchase(let emotion):
            return emotion.rawValue
        case .sales(let emotion):
            return emotion.rawValue
        }
    }
    
    var name: String {
        switch self {
        case .purchase(let emotion):
            return emotion.name
        case .sales(let emotion):
            return emotion.name
        }
    }
}

enum PurchaseEmotions: String, CaseIterable, Identifiable, Codable {
    case excitement = "🤩"
    case confidence = "🤔"
    case normal = "😐"
    case anxiety = "😨"
    case frustration = "😞"
    case anguish = "😖"
    
    var id: Self { self }

    /// 感情に対応する日本語名
    var name: String {
        switch self {
        case .excitement: return "興奮・期待"
        case .confidence: return "熟考・自信"
        case .normal: return "無"
        case .anxiety: return "不安・恐怖"
        case .frustration: return "不満・妥協"
        case .anguish: return "苦悩"
        }
    }
    
    #if DEBUG
    static var random: PurchaseEmotions {
        return allCases.randomElement()!
    }
    #endif
}

enum SalesEmotions: String, CaseIterable, Identifiable, Codable {
    case satisfaction = "🤑"
    case relief = "😌"
    case accomplishment = "🥳"
    case normal = "😐"
    case regret = "😭"
    case sadness = "😱"
    case angry = "🤬"
    
    var id: Self { self }
    
    var name: String {
        switch self {
        case .satisfaction: return "満足"
        case .relief: return "安堵"
        case .accomplishment: return "達成感"
        case .normal: return "無"
        case .regret: return "後悔・悲しみ"
        case .sadness: return "絶望"
        case .angry: return "怒り"
        }
    }
    
    #if DEBUG
    static var random: SalesEmotions {
        return allCases.randomElement()!
    }
    #endif
}

struct AddScreen: View {
    @Environment(\.modelContext) private var context
    @Binding var showAddStockView: Bool
    
    @State private var code = ""
    @State private var market: Market = .tokyo
    @State private var name = ""
    @State private var date = Date.fromToday()
    @State private var amountText = ""
    @State private var sharesText = ""
    @State private var emotion: Emotion = Emotion.purchase(.normal)
    @State private var reason = ""
    @State private var selectedTags: [CategoryTag] = []
    
    @State private var keyboardIsPresented: Bool = false
    
    var amount: Double {
        Double(amountText) ?? 0
    }
    
    var shares: Int {
        Int(sharesText) ?? 0
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    StockFormView(
                        code: $code, market: $market, name: $name,
                        date: $date, amountText: $amountText,
                        sharesText: $sharesText, emotion: $emotion,
                        reason: $reason, selectedTags: $selectedTags
                    )
                }
            }
            .navigationTitle("追加")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("dismiss", systemImage: "xmark") {
                        showAddStockView.toggle()
                    }
                }
                
                let isDisable = code.isEmpty || amount == 0 || shares == 0
                ToolbarItem(placement: .topBarTrailing) {
                    Button (
                        action: {
                            saveAction()
                        },
                        label: {
                        HStack {
                            Image(systemName: "externaldrive")
                            Text("追加")
                        }
                    })
                    .disabled(isDisable)
                }
            }
        }
        .withKeyboardToolbar(keyboardIsPresented: $keyboardIsPresented)
    }
    
    private func saveAction() {
        let tradeInfo = StockTradeInfo(
            amount: Double(amountText) ?? 0,
            shares: Int(sharesText) ?? 0,
            date: date, emotion: emotion, reason: reason
        )
        let stockRecord = StockRecord(
            code: code, market: market, name: name,
            purchase: tradeInfo, sales: [],
            tags: selectedTags.map { Tag(categoryTag: $0) }
        )
        context.insert(stockRecord)
        try? context.save()
        showAddStockView.toggle()
    }
}

#Preview {
    AddScreen(showAddStockView: .constant(true))
}

