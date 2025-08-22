//
//  Date+.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/21.
//

import Foundation

enum DateFormatType: String {
    case md = "M/d"
}

extension Date {
    func formatted(as type: DateFormatType) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = type.rawValue
        return dateFormatter.string(from: self)
    }
}
