//
//  StockTradeInfo.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/19.
//

import Foundation
import SwiftData

@Model
final class StockTradeInfo: Identifiable, NSCopying {
    var amount: Double
    var shares: Int
    var date: Date
    var emotion: Emotion
    var reason: String
   

    init(amount: Double, shares: Int, date: Date, emotion: Emotion, reason: String) {
        self.amount = amount
        self.shares = shares
        self.date = date
        self.emotion = emotion
        self.reason = reason
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        return StockTradeInfo(amount: amount, shares: shares, date: date, emotion: emotion, reason: reason)
    }
}
