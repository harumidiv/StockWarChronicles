//
//  CustomCalendarView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/10/22.
//

import SwiftUI

// --- データモデル ---
struct ExpenseItem: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Int
    let name: String
}

struct HistoryCalendarView: View {
    @State private var displayDate: Date = Date()
    @State private var selectedDate: Date?
    
    // スクリーンショットに基づくモックデータ
    private let expenses: [ExpenseItem] = [
        ExpenseItem(
            date: Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 15))!,
            amount: -10000,
            name: "サンプル支出"
        ),
        // --- 追加データ（テスト用） ---
        // 15日に複数の項目がある場合
        ExpenseItem(
            date: Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 15))!,
            amount: -800,
            name: "ランチ"
        ),
        ExpenseItem(
            date: Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 22))!,
            amount: -10000,
            name: "qwっs" // スクリーンショット下部の項目
        )
    ]
    
    private var days: [Date?] {
        generateDays(for: displayDate)
    }
    
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    private var totalExpense: Int {
        let calendar = Calendar.current
        let monthlyExpenses = expenses.filter {
            calendar.isDate($0.date, equalTo: displayDate, toGranularity: .month)
        }
        return monthlyExpenses.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            MonthHeaderView(displayDate: $displayDate, total: totalExpense)
                .padding()
            
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
            
            LazyVGrid(columns: columns, spacing: 15) {
                ForEach(0..<days.count, id: \.self) { index in
                    let date = days[index]
                    
                    let isSelected = selectedDate != nil && date != nil && Calendar.current.isDate(selectedDate!, inSameDayAs: date!)
                    
                    DayCell(
                        date: date,
                        amount: dayTotalAmount(for: date),
                        isSelected: isSelected,
                        onTap: {
                            selectedDate = date
                        }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            List {
                ForEach(monthAmountList(for: selectedDate)) { item in
                    ExpenseRowView(item: item)
                }
            }
            .listStyle(.plain)
            .frame(height: 100)
            
            Spacer()
            
        }
    }
    
    private func generateDays(for date: Date) -> [Date?] {
        let calendar = Calendar.current
        
        // 1. 月の初日と日数を取得
        guard let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
              let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth) else {
            return []
        }
        
        // 2. 初日の曜日を取得 (1 = 日曜, 2 = 月曜, ...)
        let weekdayOfFirst = calendar.component(.weekday, from: firstDayOfMonth)
        
        // 3. 前月分の空白（nil）の数を計算
        let paddingDays = weekdayOfFirst - 1 // 日曜 (1) なら 0個
        
        var allDays: [Date?] = []
        
        // 4. 空白（nil）を配列に追加
        allDays.append(contentsOf: Array(repeating: nil, count: paddingDays))
        
        // 5. 当月の日付を配列に追加
        for day in 0..<range.count {
            if let date = calendar.date(byAdding: .day, value: day, to: firstDayOfMonth) {
                allDays.append(date)
            }
        }
        
        return allDays
    }
    
    private func monthAmountList(for date: Date?) -> [ExpenseItem] {
        guard let date = date else { return [] }
        // 同じ日の項目をすべてフィルタリング
        return expenses.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    private func dayTotalAmount(for date: Date?) -> Int? {
        guard let date = date else { return nil }
        let sameDayExpenses = expenses.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
        guard !sameDayExpenses.isEmpty else { return nil }
        return sameDayExpenses.reduce(0) { $0 + $1.amount }
    }
}

struct MonthHeaderView: View {
    @Binding var displayDate: Date
    var total: Int
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }
    
    var body: some View {
        VStack {
            
            HStack(alignment: .bottom) {
                // TODO: 10月損益のような形にしたい
                Text("合計損益:")
                    .font(.title)
                Spacer()
                Text("\(total)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(total >= 0 ? .red : .blue)
                Text("円")
                    .font(.title)
                
            }
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .padding()
                }
                .tint(.primary)
                .frame(width: 50)
                .contentShape(Rectangle())
                
                Text(dateFormatter.string(from: displayDate))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .padding()
                }
                .tint(.primary)
                .frame(width: 50)
                .contentShape(Rectangle())
                
                Spacer()
                
                
            }
        }
    }
    
    private func changeMonth(by amount: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: amount, to: displayDate) {
            displayDate = newDate
        }
    }
}

struct DayCell: View {
    let date: Date?
    let amount: Int?
    
    let isSelected: Bool
    let onTap: () -> Void
    
    private var isToday: Bool {
        guard let date = date else { return false }
        return Calendar.current.isDateInToday(date)
    }
    
    // TODO: extensionに移動させる
    private var dayString: String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        Button(action: {
            if date != nil {
                onTap()
            }
        }) {
            VStack(spacing: 4) {
                if date != nil {
                    Text(dayString)
                        .font(.callout)
                        .fontWeight(.medium)
                        .frame(width: 32, height: 32)
                        .background(backgroundCircle)
                        .overlay(selectionOverlay)
                        .foregroundColor(textColor)
                    
                    if let amount = amount {
                        Text("\(amount)")
                            .font(.caption2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .foregroundColor(amount > 0 ? .red: .blue)
                    } else {
                        Text(" ")
                            .font(.caption2)
                    }
                    
                } else {
                    Spacer()
                        .frame(height: 50)
                }
            }
            .frame(height: 50)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var backgroundCircle: some View {
        if isToday {
            Circle().fill(Color.yellow.opacity(0.8))
        }
    }
    
    @ViewBuilder
    private var selectionOverlay: some View {
        if isSelected {
            Circle()
                .stroke(Color.green, lineWidth: 2)
        }
    }
    
    private var textColor: Color {
        if isToday {
            return .black
        }
        return .primary
    }
}

struct ExpenseRowView: View {
    let item: ExpenseItem
    
    var body: some View {
        HStack {
            Text(item.name)
            Spacer()
            Text("¥\(item.amount)")
                .foregroundColor(item.amount < 0 ? .red : .primary)
        }
        .padding(.horizontal)
    }
}
