//
//  StockRecord.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/19.
//

import SwiftData
import SwiftUI

@Model
final class StockRecord {
    var code: String
    private var marketRawValue: String
    var name: String
    var position: Position
    var purchase: StockTradeInfo
    var sales: [StockTradeInfo]
    @Attribute var tagDatas: [Data] = []
    
    // 計算プロパティで Market に変換
    var market: Market {
        get { Market(rawValue: marketRawValue) ?? .none }
        set { marketRawValue = newValue.rawValue }
    }
    
    var tags: [Tag] {
        get { tagDatas.compactMap { try? JSONDecoder().decode(Tag.self, from: $0) } }
        set { tagDatas = newValue.compactMap { try? JSONEncoder().encode($0) } }
    }
    
    init(code: String, market: Market, name: String, position: Position, purchase: StockTradeInfo, sales: [StockTradeInfo] = [], tags: [Tag] = []) {
        self.code = code
        self.marketRawValue = market.rawValue
        self.name = name
        self.position = position
        self.purchase = purchase
        self.sales = sales
        self.tagDatas = tags.compactMap { try? JSONEncoder().encode($0) }
    }
    
    /// 購入から売却まで完了しているか
    var isTradeFinish: Bool {
        let totalSold = sales.map(\.shares).reduce(0, +)
        return purchase.shares == totalSold
    }
    
    ///. 現在保有している残りの株数
    var remainingShares: Int {
        let totalSold = sales.map(\.shares).reduce(0, +)
        return purchase.shares - totalSold
    }
    
    /// 取引完了している時の保有日数
    var holdingPeriod: Int {
        guard let saleDate = sales.last?.date else {
            return -1
        }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: purchase.date)
        let end = calendar.startOfDay(for: saleDate)
        
        let components = calendar.dateComponents([.day], from: start, to: end)
        
        return components.day ?? 0
    }
    
    /// 取引完了している時の保有日数
    var numberOfDaysHeld: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: purchase.date)
        let end = calendar.startOfDay(for: Date())
        
        let components = calendar.dateComponents([.day], from: start, to: end)
        
        return components.day ?? 0
    }
    
    /// 損益の金額
    var profitAndLoss: Int {
        let totalPurchaseAmount = Double(purchase.shares) * purchase.amount
        let totalSalesAmount = sales.map { Double($0.shares) * $0.amount }.reduce(0, +)
        
        var totalProfitAndLoss: Double
        switch position {
        case .buy:
            // For a buy position, profit is from selling higher than the purchase price
            totalProfitAndLoss = totalSalesAmount - totalPurchaseAmount
        case .sell:
            // For a sell position, profit is from buying back lower than the sales price
            totalProfitAndLoss = totalPurchaseAmount - totalSalesAmount
        }
        
        return Int(totalProfitAndLoss)
    }
    
    /// 損益の%
    var profitAndLossParcent: Double? {
        if !isTradeFinish {
            return nil
        }
        
        let totalPurchaseAmount = Double(purchase.shares) * purchase.amount
        let totalSalesAmount = sales.map { Double($0.shares) * $0.amount }.reduce(0, +)
        
        var totalProfitAndLoss: Double
        switch position {
        case .buy:
            // Buy position: (Sell price - Buy price)
            totalProfitAndLoss = totalSalesAmount - totalPurchaseAmount
        case .sell:
            // Sell position: (Buy price - Sell price)
            totalProfitAndLoss = totalPurchaseAmount - totalSalesAmount
        }
        
        guard totalPurchaseAmount != 0 else {
            return nil
        }
        
        let profitAndLossPercentage = (totalProfitAndLoss / totalPurchaseAmount) * 100
        
        return profitAndLossPercentage
    }
    
    /// 外部から受け取った売却情報と、買い情報・ポジションを考慮して損益率を計算します。
    /// - Parameter sellInfo: 1つの売却情報
    /// - Returns: 計算された損益率（%）。購入金額が0の場合はnil。
    func profitAndLossParcent(with sellInfo: StockTradeInfo) -> Double? {
        let totalProfitAndLoss: Double
        switch self.position {
        case .buy:
            // 買いポジション: (売却価格 - 購入価格)
            totalProfitAndLoss = sellInfo.amount - purchase.amount
        case .sell:
            // 売りポジション: (購入価格 - 売却価格)
            totalProfitAndLoss = purchase.amount - sellInfo.amount
        }
        
        // 購入金額が0の場合はnilを返す
        guard purchase.amount != 0 else {
            return nil
        }
        
        // 正しいパーセント計算: 損益を**購入金額で割る**
        let profitAndLossPercentage = (totalProfitAndLoss / purchase.amount) * 100
        
        return profitAndLossPercentage
    }
}


#if DEBUG
extension StockRecord {
    /// プレビュー用のモックデータを生成する静的プロパティ
    static var mockRecords: [StockRecord] {
        [
            // 損益確定済みの取引 (購入1回 + 売却1回)
            StockRecord(
                code: "7203", // トヨタ自動車
                market: .tokyo,
                name: "トヨタ自動車",
                position: .buy,
                purchase: StockTradeInfo(amount: 2500.0, shares: 100, date: Date.from(year: 2024, month: 1, day: 10), emotion: Emotion.purchase(.random), reason: "長期保有目的で購入"),
                sales: [StockTradeInfo(amount: 2800.0, shares: 100, date: Date.from(year: 2024, month: 3, day: 15), emotion: Emotion.sales(.random), reason: "目標価格に到達したため売却")],
                tags: [.init(name: "長期保有", color: .green)]
            ),
            
            // 部分的に売却した取引 (現在も保有中)
            StockRecord(
                code: "9984", // ソフトバンクグループ
                market: .tokyo,
                name: "ソフトバンクグループ",
                position: .buy,
                purchase: StockTradeInfo(amount: 6500.0, shares: 50, date: Date.from(year: 2024, month: 2, day: 5), emotion: Emotion.purchase(.random), reason: "今後の成長を期待して購入"),
                sales: [StockTradeInfo(amount: 7000.0, shares: 25, date: Date.from(year: 2024, month: 4, day: 20), emotion: Emotion.sales(.random), reason: "一部を利益確定")]
            ),
            
            // 損切りした取引1
            StockRecord(
                code: "6758", // ソニーグループ
                market: .tokyo,
                name: "ソニーグループ",
                position: .buy,
                purchase: StockTradeInfo(amount: 15000.0, shares: 10, date: Date.from(year: 2024, month: 5, day: 1), emotion: Emotion.purchase(.random), reason: "技術トレンドの動向を見て購入"),
                sales: [StockTradeInfo(amount: 14500.0, shares: 10, date: Date.from(year: 2024, month: 6, day: 5), emotion: Emotion.sales(.random), reason: "想定外の業績下方修正のため損切り")]
            ),
            
            // 損切りした取引2
            StockRecord(
                code: "2058", // ヒガシマル
                market: .hukuoka,
                name: "ヒガシマル",
                position: .buy,
                purchase: StockTradeInfo(amount: 1000.0, shares: 10, date: Date.from(year: 2024, month: 5, day: 1), emotion: Emotion.purchase(.random), reason: "技術トレンドの動向を見て購入"),
                sales: [StockTradeInfo(amount: 800.0, shares: 10, date: Date.from(year: 2024, month: 8, day: 5), emotion: Emotion.sales(.random), reason: "想定外の業績下方修正のため損切り")]
            ),
            
            // 損切りした取引3
            StockRecord(
                code: "350A", // デジタルグリッド
                market: .tokyo,
                name: "デジタルグリッド",
                position: .buy,
                purchase: StockTradeInfo(amount: 12000.0, shares: 10, date: Date.from(year: 2024, month: 5, day: 1), emotion: Emotion.purchase(.random), reason: "技術トレンドの動向を見て購入"),
                sales: [StockTradeInfo(amount: 11200.0, shares: 10, date: Date.from(year: 2024, month: 5, day: 5), emotion: Emotion.sales(.random), reason: "想定外の業績下方修正のため損切り")]
            ),
            
            // 保有中の取引 (売却履歴なし)
            StockRecord(
                code: "9501", // 東京電力ホールディングス
                market: .tokyo,
                name: "東京電力HD",
                position: .buy,
                purchase: StockTradeInfo(amount: 700.0, shares: 200, date: Date.from(year: 2024, month: 7, day: 1), emotion: Emotion.purchase(.random), reason: "高配当を期待して購入"),
                tags:  [.init(name: "長期保有", color: .green), .init(name: "高配当", color: .yellow)]
            ),
            
            // 保有中の取引 (タグ大量)
            StockRecord(
                code: "148A", // 東京電力ホールディングス
                market: .tokyo,
                name: "ハッチ・ワーク",
                position: .buy,
                purchase: StockTradeInfo(amount: 2100.0, shares: 200, date: Date.from(year: 2024, month: 7, day: 1), emotion: Emotion.purchase(.random), reason: "高配当を期待して購入"),
                tags:  [.init(name: "長期保有", color: .green),
                        .init(name: "高配当", color: .yellow),
                        .init(name: "信用買い", color: .red),
                        .init(name: "長い名前のタグ長い名前のタグ名前のタグ", color: .purple),
                        .init(name: "AAA", color: .black),
                        .init(name: "BBB", color: .orange),
                        .init(name: "CCC", color: .indigo),
                ]
            ),
            
            // 複数の売却履歴がある取引
            StockRecord(
                code: "8306", // 三菱UFJフィナンシャル・グループ
                market: .tokyo,
                name: "三菱UFJFG",
                position: .buy,
                purchase: StockTradeInfo(amount: 1200.0, shares: 300, date: Date.from(year: 2024, month: 1, day: 20), emotion: Emotion.purchase(.random), reason: "金利上昇を見込んで購入"),
                sales: [
                    StockTradeInfo(amount: 1300.0, shares: 150, date: Date.from(year: 2024, month: 2, day: 15), emotion: Emotion.sales(.random), reason: "一部利益確定"),
                    StockTradeInfo(amount: 1350.0, shares: 150, date: Date.from(year: 2024, month: 3, day: 1), emotion: Emotion.sales(.random), reason: "残りも全て利益確定")
                ]
            )
        ]
    }
}
#endif

