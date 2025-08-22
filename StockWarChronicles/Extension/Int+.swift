//
//  Int+.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/22.
//

import Foundation

extension Int {
    func withComma() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? ""
    }
}
