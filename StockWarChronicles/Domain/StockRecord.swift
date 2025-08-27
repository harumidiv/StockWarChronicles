//
//  StockRecord.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/19.
//

import SwiftData
import Foundation

@Model
final class StockRecord {
    var code: String
    private var marketRawValue: String
    var name: String
    var purchase: StockTradeInfo
    var sales: [StockTradeInfo]
    var tags: [Tag]

    // 計算プロパティで Market に変換
    var market: Market {
        get { Market(rawValue: marketRawValue) ?? .none }
        set { marketRawValue = newValue.rawValue }
    }

    init(code: String, market: Market, name: String, purchase: StockTradeInfo, sales: [StockTradeInfo] = [], tags: [Tag] = []) {
        self.code = code
        self.marketRawValue = market.rawValue
        self.name = name
        self.purchase = purchase
        self.sales = sales
        self.tags = tags
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
    
    /// 損益の金額
    var profitAndLoss: Int {
        // 購入金額を計算
        let totalPurchaseAmount = Double(purchase.shares) * purchase.amount
        
        // 売却金額の合計を計算
        let totalSalesAmount = sales.map { Double($0.shares) * $0.amount }.reduce(0, +)
        
        // 損益を計算
        let totalProfitAndLoss = totalSalesAmount - totalPurchaseAmount
        
        // 金額を文字列にフォーマットして返す
        return Int(totalProfitAndLoss)
    }
    
    /// 損益の%
    var profitAndLossParcent: Double? {
        // 保有中の場合はnilを返す
        if !isTradeFinish {
            return nil
        }
        
        // 購入金額を計算
        let totalPurchaseAmount = Double(purchase.shares) * purchase.amount
        
        // 売却金額の合計を計算
        let totalSalesAmount = sales.map { Double($0.shares) * $0.amount }.reduce(0, +)
        
        // 損益を金額で計算
        let totalProfitAndLoss = totalSalesAmount - totalPurchaseAmount
        
        // 損益をパーセントで計算
        guard totalPurchaseAmount != 0 else {
            return nil // 購入金額が0の場合はnilを返す
        }
        
        let profitAndLossPercentage = (totalProfitAndLoss / totalPurchaseAmount) * 100
        
        // 計算結果のDoubleをそのまま返す
        return profitAndLossPercentage
    }
}
