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
                VStack {
                    stableView()
                    chartView()
                }
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
                    } else if date.isSameYearMonthDayContained(in: record.sales.map { $0.date }) {
                        PointMark(x: .value("time", date),
                                  y: .value("price", price))
                        .foregroundStyle(.red)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)  // たて軸を左側に表示
        }
        .chartXAxisLabel(position: .bottom, alignment: .center) {
            Text("Time [s]")
        }  // 軸ラベルをグラフの下側の左右中心に表示
        .chartYAxisLabel(position: .leading, alignment: .center, spacing: 0) {
            Text("Voltage [mV]")
        }  // 軸ラベルをグラフの左側の上下中央に表示し、周りの要素とのスペースをなくす
    }
    
    private func stableView() -> some View {
        Form {
            Section(header: Text("サマリー")) {
                VStack(alignment: .leading, spacing: 8) {
                    
                    HStack {
                        Text("損益")
                        Spacer()
                        Text(record.profitAndLoss.description + "円")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("保有日数")
                        Spacer()
                        Text("8日")
                    }
                    
                    HStack {
                        Text("株数")
                        Spacer()
                        Text(record.purchase.shares.description + "株")
                            .foregroundColor(.green)
                    }
                }
                .padding(.vertical, 4)
            }
            
            Section(header: Text("騰落率 \(String(format: "%.1f", record.profitAndLossParcent ?? 0))％")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("8/16 ~ 8/21")
                        Spacer()
                        Text("300株 5%")
                    }
                    HStack {
                        Text("8/16 ~ 8/25")
                        Spacer()
                        Text("700株 15%")
                    }
                    HStack {
                        Text("8/16 ~ 10/5")
                        Spacer()
                        Text("100株 50%")
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
