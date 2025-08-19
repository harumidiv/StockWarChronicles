//
//  StockRecord.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/19.
//

import SwiftData

@Model
final class StockRecord {
    var code: String
    var name: String
    var purchase: StockTradeInfo
    var sales: [StockTradeInfo]
    var tags: [Tag]

    init(code: String, name: String, purchase: StockTradeInfo, sales: [StockTradeInfo] = [], tags: [Tag] = []) {
        self.code = code
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
}
