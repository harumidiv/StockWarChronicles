//
//  OverallPerformanceView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/06.
//

import SwiftUI
import FoundationModels

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
                   return "[" + $0.emotion.emoji + ":" + $0.reason + "]"
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
                    return "[" + $0.emotion.emoji + ":" + $0.reason + "]"
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
                
                summarryView
                
                PerformanceChartView(monthlyData: monthlyPerformance)
                    .frame(height: 200)
                
                aiWinAdviceView
                aiLoseAdviceView
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
    
    var summarryView: some View {
        HStack {
            VStack(alignment: .leading) {
                let totalProfitAndLoss = calculator.calculateTotalProfitAndLoss(from: records)
                MetricView(label: "合計損益", value: totalProfitAndLoss.withComma(), unit: "円", iconName: "dollarsign.circle", color: totalProfitAndLoss >= 0 ? .red : .blue)
                MetricView(label: "平均保有日数", value: Int(calculator.calculateAverageHoldingPeriod()).description, unit: "日", iconName: "calendar", color: .primary)
                
                let winRate: Double = calculator.calculateWinRate() ?? 0.0
                MetricView(label: "勝率", value: String(format: "%.1f",winRate), unit: "", iconName: "chart.pie.fill", color: winRate >= 50 ? .red : .blue)
            }
            Spacer()
            
            VStack(alignment: .leading) {
                let totalAmount = calculator.calculateAverageProfitAndLossAmount() ?? 0.0
                MetricView(label: "平均損益額", value: Int(totalAmount).withComma(), unit: "円", iconName: "banknote.fill", color: totalAmount >= 0 ? .red : .blue)
                
                let averageParceht: Double = calculator.calculateAverageProfitAndLossPercent() ?? 0.0
                MetricView(label: "平均%", value: String(format: "%.1f", averageParceht), unit: "%", iconName: "percent", color: averageParceht >= 0 ? .red : .blue)
                
                MetricView(label: "取引回数", value: records.count.description, unit: "回", iconName: "repeat.circle.fill", color: .primary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    var aiWinAdviceView: some View {
        let instructions = """
        あなたはプロのトレードコーチです。
        ユーザーのトレード記録と感情メモを分析し、勝った原因と今後の改善策を明確に示してください。
        [感情:メモ]の形でデータを渡されます
        感情的にならず、客観的かつ実践的に回答してください。
        出力は次の形式にしてください：
        1. どんな成功が多かったか
        2. 改善案
        """
        
        return NavigationLink(destination: AdviceView(navigationTitle: "勝ちトレードAI分析", instructions: instructions, prompt: filteredWinRecordsMemo.joined(separator: ","))) {
            HStack(spacing: 4) {
                Text("勝ちトレードAI分析")
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right.dotted.chevron.right")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 12, height: 12)
            }
            .padding(8)
        }
    }
    
    var aiLoseAdviceView: some View {
        let instructions = """
        あなたはプロのトレードコーチです。
        ユーザーのトレード記録と感情メモを分析し、負けた原因と今後の改善策を明確に示してください。
        [感情:メモ]の形でデータを渡されます
        感情的にならず、客観的かつ実践的に回答してください。
        出力は次の形式にしてください：
        1. どんな失敗が多かったか
        2. 改善案
        """
        
        return NavigationLink(destination: AdviceView(navigationTitle: "負けトレードAI分析", instructions: instructions, prompt: filteredLoseRecordsMemo.joined(separator: ","))) {
            HStack(spacing: 4) {
                Text("負けトレードAI分析")
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right.dotted.chevron.right")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 12, height: 12)
            }
            .padding(8)
        }
    }
        
}
#if DEBUG
#Preview {
    OverallPerformanceView(records: StockRecord.mockRecords, selectedYear: .constant(2024))
}
#endif
