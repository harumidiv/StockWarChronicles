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
    
    /// 年月日を比較
    func isSameYearMonthDay(as other: Date, calendar: Calendar = .current) -> Bool {
        let components: Set<Calendar.Component> = [.year, .month, .day]
        let c1 = calendar.dateComponents(components, from: self)
        let c2 = calendar.dateComponents(components, from: other)
        return c1 == c2
    }
    
    /// 配列内に同じ年月日が含まれているかを判定
    func isSameYearMonthDayContained(in dates: [Date], calendar: Calendar = .current) -> Bool {
        let components: Set<Calendar.Component> = [.year, .month, .day]
        let selfComp = calendar.dateComponents(components, from: self)
        
        return dates.contains {
            calendar.dateComponents(components, from: $0) == selfComp
        }
    }
        
}
