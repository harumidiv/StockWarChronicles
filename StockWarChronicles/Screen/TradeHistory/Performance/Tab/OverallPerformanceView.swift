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
    
    private var calculator: PerformanceCalculator {
        return PerformanceCalculator(records: records)
    }
    
    var filteredWinRecordsMemo: [String] {
        records
            .filter { $0.profitAndLossParcent ?? 0.0 > 0.0}
            .flatMap { $0.sales }
            .map { $0.reason }
            .filter { !$0.isEmpty }
    }
    
    var filteredLoseRecordsMemo: [String] {
        records
            .filter { $0.profitAndLossParcent ?? 0.0 < 0.0}
            .flatMap { $0.sales }
            .map { $0.reason }
            .filter { !$0.isEmpty }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("\(selectedYear.description)年 総合サマリー")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack {
                    HStack {
                        MetricView(label: "勝率", value: String(format: "%.2f%%", calculator.calculateWinRate() ?? 0.0), iconName: "chart.pie.fill")
                        Spacer()
                        MetricView(label: "平均損益額", value: String(format: "%.0f円", calculator.calculateAverageProfitAndLossAmount() ?? 0.0), iconName: "dollarsign.circle")
                    }
                    HStack {
                        MetricView(label: "平均保有日数", value: String(format: "%.1f日", calculator.calculateAverageHoldingPeriod() ?? 0.0), iconName: "calendar")
                        Spacer()
                        MetricView(label: "平均%", value: String(format: "%.2f%%", calculator.calculateAverageProfitAndLossPercent() ?? 0.0), iconName: "percent")
                        
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 0){
                    Text("勝ちトレードメモ一覧")
                        .font(.title3)
                        .fontWeight(.bold)
                    ForEach(filteredWinRecordsMemo, id: \.self) { memo in
                        Text(memo)
                    }
                }
                VStack(alignment: .leading, spacing: 0){
                    Text("負けトレードメモ一覧")
                        .font(.title3)
                        .fontWeight(.bold)
                    ForEach(filteredLoseRecordsMemo, id: \.self) { memo in
                        Text(memo)
                    }
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
