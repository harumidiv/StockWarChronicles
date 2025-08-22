//
//  StockRecordDetailView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/21.
//

import SwiftUI
import Charts

struct StockRecordDetailView: View {
    let record: StockRecord
    @State private var isLoading: Bool = true
    @State private var chartData: [MyStockChartData] = []
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .scaleEffect(2)
            } else {
                stableView()
            }
                
        }
        .navigationTitle(record.code + " " + record.name)
        .task {
            isLoading = true
            
            let calendar = Calendar.current
            guard let endDate = record.sales.last?.date,
                  let oneWeekAfterSale = calendar.date(byAdding: .day, value: 7, to: endDate),
                  let oneWeekBeforePurchase = calendar.date(byAdding: .day, value: -7, to: record.purchase.date) else {
                isLoading = false
                return
            }

            
            let result = await YahooYFinanceAPIService().fetchStockChartData(code: record.code, startDate: oneWeekBeforePurchase, endDate: oneWeekAfterSale)
            
            switch result {
            case .success(let chartData):
                self.chartData = chartData
                
            case .failure(let error):
                print(error)
            }
            
            isLoading = false
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
    
    private func stableView() -> some View {
        Form {
            Section(header: Text("サマリー")) {
                VStack(alignment: .leading, spacing: 8) {
                    
                    HStack {
                        Text("損益")
                        Spacer()
                        Text(record.profitAndLoss.withComma() + "円")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("保有日数")
                        Spacer()
                        Text(record.holdingPeriod.description + "日")
                    }
                    
                    HStack {
                        Text("株数")
                        Spacer()
                        Text(record.purchase.shares.description + "株")
                            .foregroundColor(.green)
                    }
                    chartView()
                }
            }
            
            Section(header: Text("騰落率 \(String(format: "%.1f", record.profitAndLossParcent ?? 0))％")) {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(record.sales) { sale in
                        HStack {
                            HStack(spacing: 0) {
                                Text(record.purchase.date.formatted(as: .md))
                                    .font(.subheadline)
                                Text("~")
                                Text(sale.date.formatted(as: .md))
                                    .font(.subheadline)
                            }
                            
                            Text(sale.shares.description + "株")
                            
                            Spacer()
                            
                            let purchaseAmount = record.purchase.amount * Double(sale.shares)
                            let salesAmount = sale.amount * Double(sale.shares)
                            let totalProfitAndLoss = salesAmount - purchaseAmount
                            let profitAndLossPercentage = (totalProfitAndLoss / purchaseAmount) * 100
                            
                            Text(String(format: "%.1f", profitAndLossPercentage) + "％")
                                .font(.subheadline)
                                .foregroundColor(profitAndLossPercentage >= 0 ? .red : .blue)
                        }
                    }
                }
            }
            
            Section(header: Text("購入根拠")) {
                Text("上昇トレンド")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            }
            
            Section(header: Text("売却根拠")) {
                Text("決算でコケた")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            }
        }
    }
}

#Preview {
    let purchase = StockTradeInfo(amount: 5000, shares: 100, date: Date(), reason: "成長期待")
    let sale = StockTradeInfo(amount: 6000, shares: 100, date: Date(), reason: "目標達成")
    let record = StockRecord(code: "140A", name: "ハッチ・ワーク", purchase: purchase, sales: [sale])
    StockRecordDetailView(record: record)
}
