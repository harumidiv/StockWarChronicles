//
//  Emotion.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/07.
//

import Foundation

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
