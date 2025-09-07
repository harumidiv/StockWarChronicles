//
//  WinningTradesView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/06.
//


import SwiftUI

struct WinningTradesView: View {
    let records: [StockRecord]
    
    @State private var selectedRecord: StockRecord? = nil
    
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
                
                HStack {
                    VStack(alignment: .leading) {
                        MetricView(label: "合計損益", value: calculator.calculateTotalProfitAndLoss(from: records).withComma() + "円", iconName: "dollarsign.circle")
                        MetricView(label: "平均%", value: String(format: "%.2f%%", summary.profitPercentage), iconName: "percent")
                        
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        MetricView(label: "平均損益額", value: "\(summary.profitAmount.withComma())円", iconName: "banknote.fill")
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
                        
                        Button(action: {
                            selectedRecord = record
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        ZStack {
                                            Circle()
                                                .foregroundColor(Color(.systemBackground))
                                                .frame(width: 24, height: 24)
                                            
                                            Image(systemName: "crown.fill")
                                                .frame(width: 16, height: 16)
                                                .foregroundColor(crownBackgroundColor(for: index))
                                        }
                                        
                                        Text(record.name)
                                            .bold()
                                        Spacer()
                                        Text("\(Double(record.profitAndLoss).withComma())円")
                                            .fontWeight(.semibold)
                                    }
                                    .padding(.bottom, 4)
                                    
                                    HStack {
                                        Text("保有日数 \(record.holdingPeriod)日")
                                        Spacer()
                                        Text(String(format: "%.2f%%", record.profitAndLossParcent ?? 0.0))
                                            .fontWeight(.semibold)
                                    }
                                }
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .tint(.primary)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(cardBackgroundColor(for: index))
                                    .shadow(color: cardShadowColor(for: index), radius: 6, x: 0, y: 3)
                            )
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding()
        }
        .navigationDestination(item: $selectedRecord) { record in
            TradeHistoryDetailScreen(record: record)
        }
    }
}

extension WinningTradesView {
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
            return Color(red: 0.9, green: 0.3, blue: 0.3).opacity(0.2)
        case 1: // 2位
            return Color(red: 0.9, green: 0.5, blue: 0.5).opacity(0.2)
        case 2: // 3位
            return Color(red: 1.0, green: 0.7, blue: 0.7).opacity(0.2)
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
