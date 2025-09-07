//
//  OverallPerformanceView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/06.
//

import SwiftUI

struct OverallPerformanceView: View {
    let records: [StockRecord]
    @Binding var selectedYear: Int
    @State private var monthlyPerformance: [MonthlyPerformance] = []
    
    @State private var winTradeExpanded: Bool = false
    @State private var loseTradeExpand: Bool = false
    
    private var calculator: PerformanceCalculator {
        return PerformanceCalculator(records: records)
    }
    
    var filteredWinRecordsMemo: [String] {
        records
            .filter { $0.profitAndLossParcent ?? 0.0 > 0.0}
            .flatMap { $0.sales }
            .map {
                if !$0.reason.isEmpty {
                   return $0.emotion.emoji + $0.reason
                }
                return ""
            }
            .filter { !$0.isEmpty }
    }
    
    var filteredLoseRecordsMemo: [String] {
        records
            .filter { $0.profitAndLossParcent ?? 0.0 < 0.0}
            .flatMap { $0.sales }
            .map {
                if !$0.reason.isEmpty {
                   return $0.emotion.emoji + $0.reason
                }
                return ""
            }
            .filter { !$0.isEmpty }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("\(selectedYear.description)年 総合サマリー")
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack {
                    VStack(alignment: .leading) {
                        let totalProfitAndLoss = calculator.calculateTotalProfitAndLoss(from: records)
                        MetricView(label: "合計損益", value: totalProfitAndLoss.withComma() + "円", iconName: "dollarsign.circle")
                        MetricView(label: "平均保有日数", value: String(format: "%.1f日", calculator.calculateAverageHoldingPeriod() ?? 0.0), iconName: "calendar")
                        
                        let winRate: Double = calculator.calculateWinRate() ?? 0.0
                        MetricView(label: "勝率", value: String(format: "%.2f%%", winRate), iconName: "chart.pie.fill")
                    }
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        let totalAmount = calculator.calculateAverageProfitAndLossAmount() ?? 0.0
                        MetricView(label: "平均損益額", value: "\(Int(totalAmount).withComma())円", iconName: "banknote.fill")
                        
                        let averageParceht: Double = calculator.calculateAverageProfitAndLossPercent() ?? 0.0
                        MetricView(label: "平均%", value: String(format: "%.2f%%", averageParceht), iconName: "percent")
                        Spacer()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                
                AccordionView(isExpanded: $winTradeExpanded, title: "勝ちトレードメモ一覧") {
                    ForEach(filteredWinRecordsMemo, id: \.self) { memo in
                        HStack() {
                            Text(memo)
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 8)
                }
                AccordionView(isExpanded: $loseTradeExpand, title: "負けトレードメモ一覧") {
                    ForEach(filteredLoseRecordsMemo, id: \.self) { memo in
                        HStack() {
                            Text(memo)
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
            .padding()
        }
        .navigationTitle("全体パフォーマンス")
        .onAppear {
            monthlyPerformance = calculator.calculateMonthlyProfit()
        }
        .onChange(of: records) { _, _ in
            monthlyPerformance = calculator.calculateMonthlyProfit()
        }
    }
}

#Preview {
    OverallPerformanceView(records: StockRecord.mockRecords, selectedYear: .constant(2024))
}
