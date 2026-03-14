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
    @Query(sort: \DayMemo.normalizedDate, order: .forward) private var memos: [DayMemo]
    
    @Environment(\.modelContext) private var context
    
    @Binding var selectedYear: Int
    
    @State private var displayDate: Date = Date()
    @State private var selectedDate: Date?
    
    @State private var isMemoSheetPresented: Bool = false
    @State private var memoText: String = ""
    
    private var days: [Date?] {
        generateDays(for: displayDate)
    }
    
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    private var totalExpense: Int {
        let calendar = Calendar.current
        let salesInMonth = records.flatMap { record -> [(record: StockRecord, saleInfo: StockTradeInfo)] in
            let matchedSales = record.sales.filter { saleInfo in
                calendar.isDate(saleInfo.date, equalTo: displayDate, toGranularity: .month)
            }
            return matchedSales.map { (record: record, saleInfo: $0) }
        }
        guard !salesInMonth.isEmpty else { return 0 }
        let totalProfitAndLoss = salesInMonth.reduce(0.0) { (currentTotal, tuple) in
            let record = tuple.record
            let saleInfo = tuple.saleInfo
            let profitPerShare: Double
            switch record.position {
            case .buy:
                profitPerShare = saleInfo.amount - record.purchase.amount
            case .sell:
                profitPerShare = record.purchase.amount - saleInfo.amount
            }
            return currentTotal + (profitPerShare * Double(saleInfo.shares))
        }
        return Int(totalProfitAndLoss)
    }
    
    private func memo(for date: Date?) -> DayMemo? {
        guard let date = date else { return nil }
        let key = DayMemo.key(for: date)
        return memos.first(where: { $0.dateKey == key })
    }
    
    private func openMemoEditor(for date: Date) {
        // selectedDate は変更しない。メモテキストだけ取得してシートを開く
        memoText = memo(for: date)?.text ?? ""
        isMemoSheetPresented = true
    }
    
    private func saveMemo() {
        let targetDate = selectedDate ?? displayDate
        let trimmed = memoText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            // 空文字なら既存メモを削除
            if let existing = memo(for: targetDate) {
                context.delete(existing)
            }
        } else if let existing = memo(for: targetDate) {
            existing.text = trimmed
        } else {
            let new = DayMemo(date: targetDate, text: trimmed)
            context.insert(new)
        }
        
        do {
            try context.save()
            memoText = ""
            isMemoSheetPresented = false
        } catch {
            print("Failed to save memo: \(error)")
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            MonthHeaderView(selectedYear: $selectedYear, selectedDate: $selectedDate, displayDate: $displayDate, total: totalExpense)
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
            .padding(.bottom, 4)
            
            List {
                Section(header:
                            HStack {
                    let effectiveDate = selectedDate ?? displayDate
                    Text("メモ")
                    Spacer()
                    Button(action: {
                        openMemoEditor(for: effectiveDate)
                    }) {
                        Image(systemName: memo(for: effectiveDate) == nil ? "plus.circle" : "pencil.circle")
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                ) {
                    let effectiveDate = selectedDate ?? displayDate
                    if let dayMemo = memo(for: effectiveDate), !dayMemo.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(dayMemo.text)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                }
                
                Section(header: Text("売却履歴")) {
                    ForEach(dailySales(for: selectedDate), id: \.sale.id) { tuple in
                        DailyExpenseRowView(record: tuple.record, sale: tuple.sale, profit: tuple.profit)
                    }
                }
            }
        }
        .sheet(isPresented: $isMemoSheetPresented) {
            NavigationStack {
                VStack(alignment: .leading) {
                    TextEditor(text: $memoText)
                        .frame(minHeight: 200)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                        .padding(.bottom, 8)
                    Spacer()
                }
                .padding()
                .navigationTitle("メモ")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("閉じる") { isMemoSheetPresented = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("保存") { saveMemo() }
                    }
                }
            }
        }
    }
    
    private func generateDays(for date: Date) -> [Date?] {
        let calendar = Calendar.current
        guard let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
              let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth) else {
            return []
        }
        let weekdayOfFirst = calendar.component(.weekday, from: firstDayOfMonth)
        let paddingDays = weekdayOfFirst - 1
        var allDays: [Date?] = []
        allDays.append(contentsOf: Array(repeating: nil, count: paddingDays))
        for day in 0..<range.count {
            if let date = calendar.date(byAdding: .day, value: day, to: firstDayOfMonth) {
                allDays.append(date)
            }
        }
        return allDays
    }
    
    private func monthAmountList(for date: Date?) -> [StockRecord] {
        guard let date = date else { return [] }
        return records.filter { record in
            record.sales.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })
        }
    }
    
    private func dayTotalAmount(for date: Date?) -> Int? {
        guard let date = date else { return nil }
        let salesOnDate = records.flatMap { record -> [(record: StockRecord, saleInfo: StockTradeInfo)] in
            let matchedSales = record.sales.filter { saleInfo in
                Calendar.current.isDate(saleInfo.date, inSameDayAs: date)
            }
            return matchedSales.map { (record: record, saleInfo: $0) }
        }
        guard !salesOnDate.isEmpty else { return nil }
        let totalProfitAndLoss = salesOnDate.reduce(0.0) { (currentTotal, tuple) in
            let record = tuple.record
            let saleInfo = tuple.saleInfo
            let profitPerShare: Double
            switch record.position {
            case .buy:
                profitPerShare = saleInfo.amount - record.purchase.amount
            case .sell:
                profitPerShare = record.purchase.amount - saleInfo.amount
            }
            return currentTotal + (profitPerShare * Double(saleInfo.shares))
        }
        return Int(totalProfitAndLoss)
    }
    
    private func dailySales(for date: Date?) -> [(record: StockRecord, sale: StockTradeInfo, profit: Int)] {
        guard let date = date else { return [] }
        let calendar = Calendar.current
        let pairs: [(StockRecord, StockTradeInfo)] = records.flatMap { record in
            record.sales.filter { calendar.isDate($0.date, inSameDayAs: date) }.map { (record, $0) }
        }
        let results: [(StockRecord, StockTradeInfo, Int)] = pairs.map { (record, sale) in
            let profitPerShare: Double
            switch record.position {
            case .buy:
                profitPerShare = sale.amount - record.purchase.amount
            case .sell:
                profitPerShare = record.purchase.amount - sale.amount
            }
            let profit = Int(profitPerShare * Double(sale.shares))
            return (record, sale, profit)
        }
        return results
    }
}

struct MonthHeaderView: View {
    @Binding var selectedYear: Int
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
            selectedYear = Calendar.current.component(.year, from: displayDate)
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
    
    private var dayString: String {
        guard let date = date else { return "" }
        return date.formatted(as: .d)
    }
    
    var body: some View {
        Button(action: {
            if date != nil { onTap() }
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
                            .foregroundColor(amount > 0 ? .red : .blue)
                    } else {
                        Text(" ")
                            .font(.caption2)
                    }
                } else {
                    Spacer().frame(height: 50)
                }
            }
            .frame(height: 50)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var backgroundCircle: some View {
        if isToday { Circle().fill(Color.yellow.opacity(0.8)) }
    }
    
    @ViewBuilder
    private var selectionOverlay: some View {
        if isSelected { Circle().stroke(Color.green, lineWidth: 2) }
    }
    
    private var textColor: Color {
        isToday ? .black : .primary
    }
}

struct DailyExpenseRowView: View {
    let record: StockRecord
    let sale: StockTradeInfo
    let profit: Int
    
    var body: some View {
        Group {
            if record.isTradeFinish {
                NavigationLink(destination: TradeHistoryDetailScreen(record: record)) {
                    content
                }
            } else {
                content
            }
        }
        .padding(.horizontal)
    }
    
    private var content: some View {
        HStack {
            Text(record.name).lineLimit(1)
            Spacer()
            Text("¥\(profit)").foregroundColor(profit < 0 ? .blue : .red)
        }
    }
}

struct ExpenseRowView: View {
    let item: StockRecord
    
    var body: some View {
        Group {
            if item.isTradeFinish {
                NavigationLink(destination: TradeHistoryDetailScreen(record: item)) {
                    content
                }
            } else {
                content
            }
        }
        .padding(.horizontal)
    }
    
    var content: some View {
        HStack {
            Text(item.name).lineLimit(1)
            Spacer()
            Text("¥\(item.profitAndLoss)").foregroundColor(item.profitAndLoss < 0 ? .blue : .red)
        }
    }
}
