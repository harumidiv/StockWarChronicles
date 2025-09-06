//
//  OverallPerformanceView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/06.
//

import SwiftUI
import Charts

struct OverallPerformanceView: View {
    let records: [StockRecord]
    @Binding var selectedYear: Int
    @State private var monthlyPerformance: [MonthlyPerformance] = []
    
    // PerformanceCalculatorのインスタンスを作成
    private var calculator: PerformanceCalculator {
        return PerformanceCalculator(records: records)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("\(selectedYear)年 総合サマリー")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // 主要なパフォーマンス指標のグリッド
                Grid(horizontalSpacing: 20, verticalSpacing: 20) {
                    GridRow {
                        MetricView(label: "平均%", value: String(format: "%.2f%%", calculator.calculateAverageProfitAndLossPercent() ?? 0.0), iconName: "percent")
                        MetricView(label: "勝率", value: String(format: "%.2f%%", calculator.calculateWinRate() ?? 0.0), iconName: "chart.pie.fill")
                    }
                    GridRow {
                        MetricView(label: "プロフィットファクター", value: String(format: "%.2f", calculator.calculateProfitFactor() ?? 0.0), iconName: "gauge.simple.fill")
                        MetricView(label: "最大ドローダウン", value: String(format: "%.2f%%", calculator.calculateMaximumDrawdown() ?? 0.0), iconName: "waveform.path.badge.minus")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // 月別損益グラフ
                VStack(alignment: .leading) {
                    Text("月別損益推移")
                        .font(.headline)
                    
                    Chart(monthlyPerformance, id: \.month) { data in
                        BarMark(
                            x: .value("月", data.month),
                            y: .value("損益", data.profitAmount)
                        )
                        .foregroundStyle(data.profitAmount >= 0 ? Color.green : Color.red)
                    }
                    .frame(height: 200)
                    .chartXAxis {
                        AxisMarks(values: .automatic) { _ in
                            AxisTick()
                            AxisValueLabel(format: .dateTime.month(.twoDigits))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: .automatic) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(String(format: "%.0f円", value.as(Double.self)!))
                        }
                    }
                }
                
                // その他の詳細データ
                Grid(horizontalSpacing: 20, verticalSpacing: 10) {
                    GridRow {
                        Text("平均損益額")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.0f円", calculator.calculateAverageProfitAndLossAmount() ?? 0.0))
                            .fontWeight(.semibold)
                    }
                    GridRow {
                        Text("平均保有日数")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.1f日", calculator.calculateAverageHoldingPeriod() ?? 0.0))
                            .fontWeight(.semibold)
                    }
                    GridRow {
                        Text("平均リスクリワードレシオ")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.2f", calculator.calculateAverageRiskRewardRatio() ?? 0.0))
                            .fontWeight(.semibold)
                    }
                    GridRow {
                        Text("総取引回数")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(records.count)+"回")
                            .fontWeight(.semibold)
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
