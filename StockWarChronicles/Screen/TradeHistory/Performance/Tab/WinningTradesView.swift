//
//  WinningTradesView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/06.
//


import SwiftUI

struct WinningTradesView: View {
    let records: [StockRecord]
    
    var body: some View {
        let calculator = PerformanceCalculator(records: records)
        
        let summary = TradeSummary(
            profitPercentage: calculator.calculateAverageProfitAndLossPercent() ?? 0,
            profitAmount: calculator.calculateAverageProfitAndLossAmount() ?? 0,
            holdingDays: calculator.calculateAverageHoldingPeriod() ?? 0,
            winRate: calculator.calculateWinRate() ?? 0,
            profitFactor: calculator.calculateProfitFactor() ?? 0,
            maxDrawdown: calculator.calculateMaximumDrawdown() ?? 0,
            riskRewardRatio: calculator.calculateAverageRiskRewardRatio() ?? 0
        )
        
        let bestTrades:[StockRecord] = records
            .filter { $0.profitAndLoss >= 0 }
            .sorted { $0.profitAndLoss > $1.profitAndLoss }
            .prefix(3)
            .map { $0 }
        
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("勝ち取引サマリー")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack {
                    HStack {
                        MetricView(label: "合計損益", value: calculator.calculateTotalProfitAndLoss(from: records).withComma() + "円", iconName: "dollarsign.circle")
                            .foregroundColor(.red)
                        Spacer()
                        MetricView(label: "平均損益額", value: String(format: "%.0f円", summary.profitAmount), iconName: "banknote.fill")
                            .foregroundColor(.red)
                    }
                    HStack {
                        MetricView(label: "平均%", value: String(format: "%.2f%%", summary.profitPercentage), iconName: "percent")
                            .foregroundColor(.red)
                        Spacer()
                        MetricView(label: "平均保有日数", value: String(format: "%d日", Int(summary.holdingDays)), iconName: "calendar")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                VStack(alignment: .leading) {
                    Text("ベスト取引トップ3")
                        .font(.headline)

                    ForEach(bestTrades.indices, id: \.self) { index in
                        let record = bestTrades[index]
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("\(index + 1)位")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(index == 0 ? .white : .black)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(index == 0 ? Color.red : Color.clear)
                                    .cornerRadius(8)
                                
                                Text(record.name)
                                Spacer()
                                Text(String(format: "%.0f円", Double(record.profitAndLoss)))
                                    .foregroundColor(.red)
                                    .fontWeight(.semibold)
                            }
                            .padding(.bottom, 4)
                            
                            HStack {
                                Text("保有日数 \(record.holdingPeriod)日")
                                Spacer()
                                Text(String(format: "%.2f%%", record.profitAndLossParcent ?? 0.0))
                                    .foregroundColor(.red)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(cardBackgroundColor(for: index))
                                .shadow(color: cardShadowColor(for: index), radius: 6, x: 0, y: 3)
                        )
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding()
        }
        .navigationTitle("勝ち取引")
    }
}

extension WinningTradesView {
    func cardBackgroundColor(for index: Int) -> Color {
        switch index {
        case 0: // 1位
            return Color(red: 0.2, green: 0.8, blue: 0.2).opacity(0.2)
        case 1: // 2位
            return Color(red: 0.4, green: 0.9, blue: 0.4).opacity(0.2)
        case 2: // 3位
            return Color(red: 0.6, green: 1.0, blue: 0.6).opacity(0.2)
        default: // 4位以下
            return Color(.systemGray6)
        }
    }

    func cardShadowColor(for index: Int) -> Color {
        switch index {
        case 0, 1, 2:
            return Color.black.opacity(0.2)
        default:
            return Color.clear
        }
    }
}

#Preview {
    WinningTradesView(records: StockRecord.mockRecords.filter{ $0.profitAndLossParcent ?? 0.0 > 0.0})
}
