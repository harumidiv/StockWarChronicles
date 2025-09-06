//
//  LosingTradesView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/06.
//


import SwiftUI

struct LosingTradesView: View {
    let records: [StockRecord]
    
    // PerformanceCalculatorのインスタンスを作成
    private var calculator: PerformanceCalculator {
        // 負け取引のみをフィルタリングして渡す
        let losingRecords = records.filter { $0.profitAndLoss < 0 }
        return PerformanceCalculator(records: losingRecords)
    }

    var summary: TradeSummary {
        return TradeSummary(
            profitPercentage: calculator.calculateAverageProfitAndLossPercent() ?? 0,
            profitAmount: calculator.calculateAverageProfitAndLossAmount() ?? 0,
            holdingDays: calculator.calculateAverageHoldingPeriod() ?? 0,
            winRate: calculator.calculateWinRate() ?? 0,
            profitFactor: calculator.calculateProfitFactor() ?? 0,
            maxDrawdown: calculator.calculateMaximumDrawdown() ?? 0,
            riskRewardRatio: calculator.calculateAverageRiskRewardRatio() ?? 0
        )
    }

    var worstTrades: [StockRecord] {
        let losingRecords = records.filter { $0.profitAndLoss < 0 }
        return losingRecords
            .sorted { $0.profitAndLoss < $1.profitAndLoss }
            .prefix(3)
            .map { $0 }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("負け取引サマリー")
                    .font(.title2)
                    .fontWeight(.bold)
                VStack {
                    HStack {
                        MetricView(label: "合計損益", value: calculator.calculateTotalProfitAndLoss(from: records).withComma() + "円", iconName: "dollarsign.circle")
                            .foregroundColor(.blue)
                        Spacer()
                        MetricView(label: "平均損益額", value: String(format: "%.0f円", summary.profitAmount), iconName: "banknote.fill")
                            .foregroundColor(.blue)
                    }
                    HStack {
                        MetricView(label: "平均%", value: String(format: "%.2f%%", summary.profitPercentage), iconName: "percent")
                            .foregroundColor(.blue)
                        Spacer()
                        MetricView(label: "平均保有日数", value: String(format: "%d日", Int(summary.holdingDays)), iconName: "calendar")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                

                VStack(alignment: .leading) {
                    Text("ワースト取引トップ3")
                        .font(.headline)

                    ForEach(worstTrades.indices, id: \.self) { index in
                        let record = worstTrades[index]
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .foregroundColor(Color(.systemBackground))
                                        .frame(width: 24, height: 24)

                                    // 前面のアイコン
                                    Image(systemName: "crown.fill")
                                        .frame(width: 16, height: 16)
                                        .foregroundColor(crownBackgroundColor(for: index))
                                }
                                
                                Text(record.name)
                                Spacer()
                                Text(String(format: "%.0f円", Double(record.profitAndLoss)))
                                    .foregroundColor(.blue)
                                    .fontWeight(.semibold)
                            }
                            .padding(.bottom, 4)
                            
                            HStack {
                                Text("保有日数 \(record.holdingPeriod)日")
                                Spacer()
                                Text(String(format: "%.2f%%", record.profitAndLossParcent ?? 0.0))
                                    .foregroundColor(.blue)
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
        .navigationTitle("負け取引")
    }
}

extension LosingTradesView {
    func crownBackgroundColor(for index: Int) -> Color {
        switch index {
        case 0:
            return Color(red: 1.0, green: 0.84, blue: 0.0)
        case 1:
            return Color(red: 0.75, green: 0.75, blue: 0.75)
        case 2:
            return Color(red: 0.8, green: 0.5, blue: 0.2)
        default:
            return .clear
        }
    }
    
    func cardBackgroundColor(for index: Int) -> Color {
        switch index {
        case 0: // 1位
            return Color(red: 0.8, green: 0.2, blue: 0.2).opacity(0.2)
        case 1: // 2位
            return Color(red: 0.9, green: 0.4, blue: 0.4).opacity(0.2)
        case 2: // 3位
            return Color(red: 1.0, green: 0.6, blue: 0.6).opacity(0.2)
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
    LosingTradesView(records: StockRecord.mockRecords.filter{ $0.profitAndLossParcent ?? 0.0 < 0.0})
}
