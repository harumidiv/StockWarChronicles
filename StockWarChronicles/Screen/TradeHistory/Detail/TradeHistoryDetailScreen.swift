//
//  TradeHistoryDetailScreen.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/21.
//

import Charts
import SwiftUI
import SwiftData

struct TradeHistoryDetailScreen: View {
    enum ScreenState {
        case loading
        case stable
    }
    @State private var screenState: ScreenState = .loading
    
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var record: StockRecord
    @State private var chartData: [MyStockChartData] = []
    
    @State private var name: String = ""
    @State private var market: Market = .tokyo
    @State private var code: String = ""
    @State private var purchaseReason: String = ""
    @State private var saleReasons: [String] = []
    
    @State private var showDeleteAlert: Bool = false
    @State private var showEditScreen: Bool = false
    
    var body: some View {
        Group {
            switch screenState {
            case .loading:
                ProgressView()
                    .scaleEffect(2)
            case .stable:
                stableView()
                    .navigationTitle(record.code + " " + record.name)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("record", systemImage: "square.and.pencil") {
                                showEditScreen = true
                            }
                        }
                    }
                    .sheet(isPresented: $showEditScreen) {
                        EditScreen(record: record)
                    }
            }
        }
        .onAppear {
            name = record.name
            market = record.market
            code = record.code
            purchaseReason = record.purchase.reason
            saleReasons = record.sales.compactMap{ $0.reason }
        }
        .task(id: screenState == .loading) {
            await fetchChartData()
        }
        .alert("本当に削除しますか？", isPresented: $showDeleteAlert) {
            Button("削除", role: .destructive) {
                deleteHistory()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("この株取引データは完全に削除されます。")
        }
    }
    
    @ViewBuilder
    private func chartView() -> some View {
        let min = chartData.compactMap{ $0.adjclose }.min()
        let max = chartData.compactMap{ $0.adjclose }.max()
        Chart {
            ForEach(chartData) { data in
                if let date = data.date, let price = data.adjclose {
                    LineMark(x: .value("time", date),
                             y: .value("price", price))
                    .opacity(0.4)
                    
                    if date.isSameYearMonthDay(as: record.purchase.date) {
                        PointMark(x: .value("time", date),
                                  y: .value("price", price))
                        .foregroundStyle(.green)
                        .annotation(position: .bottom) {
                            Text("購入")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    } else if date.isSameYearMonthDayContained(in: record.sales.map { $0.date }) {
                        PointMark(x: .value("time", date),
                                  y: .value("price", price))
                        .foregroundStyle(.red)
                        .annotation(position: .bottom) {
                            Text("売却")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartYScale(domain: [min ?? 0 * 0.95, max ?? 0 * 1.05])
    }
    
    private func editView() -> some View {
        Form {
            
            Section {
                HStack {
                    TextField("コード", text: $code)
                    Picker("", selection: $market) {
                        ForEach(Market.allCases) { market in
                            Text(market.rawValue)
                                .tag(market)
                        }
                    }
                    .pickerStyle(.menu)
                }
                TextField("名前", text: $name)
            }
            
            summarySection()
            
            Section(header: Text("騰落率 \(String(format: "%.1f", record.profitAndLossParcent ?? 0))％")
                .font(.headline)) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(record.sales) { sale in
                        HStack {
                            HStack(spacing: 0) {
                                Text(record.purchase.date.formatted(as: .md))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("~")
                                Text(sale.date.formatted(as: .md))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(sale.shares.description + "株")
                                .font(.body)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            let purchaseAmount = record.purchase.amount * Double(sale.shares)
                            let salesAmount = sale.amount * Double(sale.shares)
                            let totalProfitAndLoss = salesAmount - purchaseAmount
                            let profitAndLossPercentage = (totalProfitAndLoss / purchaseAmount) * 100
                            
                            Text(String(format: "%.1f", profitAndLossPercentage) + "％")
                                .font(.subheadline)
                                .foregroundColor(profitAndLossPercentage >= 0 ? .red : .blue)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            Section(header: Text("メモ(編集中)")) {
                TextEditor(text: $purchaseReason)
                    .frame(height: 100)
                    .padding(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.5))
                    )
            }

            Section(header: Text("メモ(編集中)").font(.headline)) {
                VStack(spacing: 0) {
                    ForEach(saleReasons.indices, id: \.self) { index in
                        TextEditor(text: $saleReasons[index])
                            .frame(height: 100)
                            .padding(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5))
                            )
                    }
                }
            }
            .listRowSeparator(.hidden)
        }
    }
    
    private func stableView() -> some View {
        Form {
            summarySection()
            
            Section(header: Text("騰落率 \(String(format: "%.1f", record.profitAndLossParcent ?? 0))％")
                .font(.headline)) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(record.sales) { sale in
                        HStack {
                            HStack(spacing: 0) {
                                Text(record.purchase.date.formatted(as: .md))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("~")
                                Text(sale.date.formatted(as: .md))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(sale.shares.description + "株")
                                .font(.body)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            let purchaseAmount = record.purchase.amount * Double(sale.shares)
                            let salesAmount = sale.amount * Double(sale.shares)
                            let totalProfitAndLoss = salesAmount - purchaseAmount
                            let profitAndLossPercentage = (totalProfitAndLoss / purchaseAmount) * 100
                            
                            Text(String(format: "%.1f", profitAndLossPercentage) + "％")
                                .font(.subheadline)
                                .foregroundColor(profitAndLossPercentage >= 0 ? .red : .blue)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            Section(header: Text("メモ").font(.headline)) {
                Text(record.purchase.reason)
                    .font(.body)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Section(header: Text("売却根拠").font(.headline)) {
                VStack(spacing: 0) {
                    ForEach(record.sales) { sale in
                        Text(sale.reason)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .listRowSeparator(.hidden)
        }
        .listStyle(.insetGrouped)
    }
    
    private func summarySection() -> some View {
        Section(header: Text("サマリー").font(.headline)) {
            VStack(alignment: .leading, spacing: 12) {
                
                HStack {
                    Text("損益")
                        .font(.subheadline)
                    Spacer()
                    Text(record.profitAndLoss.withComma() + "円")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(record.profitAndLoss >= 0 ? .red : .blue)
                }
                
                HStack {
                    Text("保有日数")
                        .font(.subheadline)
                    Spacer()
                    Text(record.holdingPeriod.description + "日")
                        .font(.body)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("株数")
                        .font(.subheadline)
                    Spacer()
                    Text(record.purchase.shares.description + "株")
                        .font(.body)
                        .fontWeight(.semibold)
                }
                
                ChipsView(tags: record.tags) { tag in
                    TagView(name: tag.name, color: tag.color)
                }
                
                if !chartData.isEmpty {
                    chartView()
                }
            }
            .padding(.vertical, 4)
        }
    }

}

// MARK: Process
extension TradeHistoryDetailScreen {
    private func fetchChartData() async {
        let calendar = Calendar.current
        guard let endDate = record.sales.last?.date,
              let oneWeekAfterSale = calendar.date(byAdding: .day, value: 7, to: endDate),
              let oneWeekBeforePurchase = calendar.date(byAdding: .day, value: -7, to: record.purchase.date) else {
            screenState = .stable
            return
        }

        
        let result = await YahooYFinanceAPIService().fetchStockChartData(code: record.code, symbol: record.market.symbol, startDate: oneWeekBeforePurchase, endDate: oneWeekAfterSale)
        
        switch result {
        case .success(let chartData):
            self.chartData = chartData
            
        case .failure(let error):
            print(error)
        }
        
        screenState = .stable
    }
    
    private func deleteHistory() {
        context.delete(record)  // モデルを削除
        do {
            try context.save() // 永続化
        } catch {
            print("削除エラー: \(error)")
        }
        
        dismiss()
    }
}

#Preview {
    let purchase = StockTradeInfo(amount: 5000, shares: 100, date: Date(), reason: "成長期待")
    let sales = [
        StockTradeInfo(amount: 6000, shares: 100, date: Date(), reason: "目標達成1"),
        StockTradeInfo(amount: 6000, shares: 100, date: Date(), reason: "目標達成2esrtdhyfgaersthgrfewqratshdytrtsegafwfrhtydtrsgeawetshratregtergetwrgearg")
        ]
    let record = StockRecord(code: "140A", market: .tokyo, name: "ハッチ・ワーク", purchase: purchase, sales: sales)
    NavigationStack {
        TradeHistoryDetailScreen(record: record)
    }
}
