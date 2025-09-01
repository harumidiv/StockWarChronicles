//
//  Date+.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/21.
//

import Foundation

enum DateFormatType: String {
    case md = "M/d"
    case yyyyMMdd = "YYYY/MM/dd"
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
    
    static func from(year: Int, month: Int, day: Int) -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return calendar.date(from: components)!
    }
        
}
