//
//  Double+.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/06.
//

import Foundation

extension Double {
    /// ダブル型の数値に3桁ごとのコンマを付けて文字列に変換します。
    /// - Returns: コンマ付きの文字列。
    func withComma() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        
        // 小数点以下を制御する場合は、以下のプロパティを設定します
        // formatter.maximumFractionDigits = 2 // 例: 小数点以下2桁まで表示
        // formatter.minimumFractionDigits = 2 // 例: 常に小数点以下2桁表示

        return formatter.string(from: NSNumber(value: self)) ?? ""
    }
}
