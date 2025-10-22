//
//  CustomCalendarView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/10/22.
//

import SwiftUI
import SwiftData

struct ExpenseItem: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Int
    let name: String
}

struct HistoryCalendarView: View {
    @Query private var records: [StockRecord]
    @Environment(\.modelContext) private var context
    
    @State private var displayDate: Date = Date()
    @State private var selectedDate: Date?
    
    private var days: [Date?] {
        generateDays(for: displayDate)
    }
    
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    private var totalExpense: Int {
        let calendar = Calendar.current
        
        // 1. 表示月に行われたすべての「売却」を、
        //    元のStockRecord（購入情報）と一緒にタプルとして抽出します。
        let salesInMonth = records.flatMap { record -> [(record: StockRecord, saleInfo: StockTradeInfo)] in
            
            // record.sales の中から表示月と一致するものをフィルタリング
            let matchedSales = record.sales.filter { saleInfo in
                calendar.isDate(saleInfo.date, equalTo: displayDate, toGranularity: .month)
            }
            
            // (record, saleInfo) のタプルの配列にして返す
            return matchedSales.map { (record: record, saleInfo: $0) }
        }
        
        // 2. その月に売却が一件もなければ 0 を返します。
        guard !salesInMonth.isEmpty else { return 0 }
        
        // 3. 抽出した売却情報タプルをループし、損益を計算して合計します（Double型で）。
        let totalProfitAndLoss = salesInMonth.reduce(0.0) { (currentTotal, tuple) in
            
            let record = tuple.record
            let saleInfo = tuple.saleInfo
            
            let profitPerShare: Double
            
            // ポジションに応じて1株あたりの損益を計算
            switch record.position {
            case .buy:
                // 買いポジション: (売却単価 - 購入単価)
                profitPerShare = saleInfo.amount - record.purchase.amount
            case .sell:
                // 売りポジション: (購入単価 - 売却単価)
                profitPerShare = record.purchase.amount - saleInfo.amount
            }
            
            // (1株あたり損益 * 売却株数) を現在の合計に加算します。
            return currentTotal + (profitPerShare * Double(saleInfo.shares))
        }
        
        // 4. 合計損益を Int として返します。
        return Int(totalProfitAndLoss)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            MonthHeaderView(selectedDate: $selectedDate, displayDate: $displayDate, total: totalExpense)
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
    
    private func monthAmountList(for date: Date?) -> [StockRecord] {
        guard let date = date else { return [] }
        
        // records が [StockRecord] の配列であると仮定します。
        return records.filter { record in
            
            // 売却日のいずれかが指定日と一致するかチェック
            // .contains(where:) を使い、sales配列内に一致する日付が1つでもあればtrueを返す
            return record.sales.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })
        }
    }
    
    /**
     * 指定された日付に発生したすべての売却（sales）による損益の合計金額を計算します。
     *
     * @param date 計算対象の日付。
     * @return その日の合計損益（Int）。取引がなかった場合は nil。
     */
    private func dayTotalAmount(for date: Date?) -> Int? {
        guard let date = date else { return nil }
        
        // 1. 指定された日付に行われたすべての売却（sales）を、
        //    元のStockRecord（購入情報など）と一緒にタプルとして抽出します。
        let salesOnDate = records.flatMap { record -> [(record: StockRecord, saleInfo: StockTradeInfo)] in
            
            // record.sales の中から指定日と一致するものをフィルタリング
            let matchedSales = record.sales.filter { saleInfo in
                Calendar.current.isDate(saleInfo.date, inSameDayAs: date)
            }
            
            // (record, saleInfo) のタプルの配列にして返します。
            // これにより、どの売却がどの購入に対応するかがわかります。
            return matchedSales.map { (record: record, saleInfo: $0) }
        }
        
        // 2. その日に売却が一件もなければ nil を返します。
        guard !salesOnDate.isEmpty else { return nil }
        
        // 3. 抽出した売却情報タプルをループし、損益を計算して合計します（Double型で）。
        let totalProfitAndLoss = salesOnDate.reduce(0.0) { (currentTotal, tuple) in
            
            let record = tuple.record
            let saleInfo = tuple.saleInfo
            
            let profitPerShare: Double
            
            // ポジションに応じて1株あたりの損益を計算
            switch record.position {
            case .buy:
                // 買いポジション: (売却単価 - 購入単価)
                profitPerShare = saleInfo.amount - record.purchase.amount
            case .sell:
                // 売りポジション: (購入単価 - 売却単価)
                profitPerShare = record.purchase.amount - saleInfo.amount
            }
            
            // (1株あたり損益 * 売却株数) を現在の合計に加算します。
            return currentTotal + (profitPerShare * Double(saleInfo.shares))
        }
        
        // 4. 合計損益を Int として返します。
        return Int(totalProfitAndLoss)
    }
}

struct MonthHeaderView: View {
    @Binding var selectedDate: Date?
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
                Button(action: {
                    changeMonth(by: -1)
                    selectedDate = nil
                }) {
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
                
                Button(action: {
                    changeMonth(by: 1)
                    selectedDate = nil
                }) {
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
    let item: StockRecord
    
    var body: some View {
        HStack {
            Text(item.name)
            Spacer()
            Text("¥\(item.profitAndLoss)")
                .foregroundColor(item.profitAndLoss < 0 ? .blue : .red)
        }
        .padding(.horizontal)
    }
}
