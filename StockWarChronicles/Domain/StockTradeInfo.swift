//
//  StockTradeInfo.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/19.
//

import Foundation
import SwiftData

@Model
final class StockTradeInfo {
    var amount: Double
    var shares: Int
    var date: Date
    var reason: String

    init(amount: Double, shares: Int, date: Date, reason: String) {
        self.amount = amount
        self.shares = shares
        self.date = date
        self.reason = reason
    }
}
