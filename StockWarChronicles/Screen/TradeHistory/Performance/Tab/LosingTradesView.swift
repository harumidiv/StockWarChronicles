//
//  LosingTradesView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/06.
//


import SwiftUI

struct LosingTradesView: View {
    let records: [StockRecord]
    let selectedYear: Int
    
    @State private var selectedRecord: StockRecord? = nil
    @State private var selectedSortType: PerformanceTradeSortType = .amount
    var worstTrades: [StockRecord] {
        let losingRecords = records.filter { $0.profitAndLoss < 0 }
        
        switch selectedSortType {
        case .amount:
            return losingRecords
                .sorted { $0.profitAndLoss < $1.profitAndLoss } // 金額ベースで損が大きい順
                .prefix(3)
                .map { $0 }
        case .percent:
            return losingRecords
                .sorted { ($0.profitAndLossParcent ?? 0) < ($1.profitAndLossParcent ?? 0) } // %ベースで損が大きい順
                .prefix(3)
                .map { $0 }
        }
    }
    
    // PerformanceCalculatorのインスタンスを作成
    private var calculator: PerformanceCalculator {
        // 負け取引のみをフィルタリングして渡す
        let losingRecords = records.filter { $0.profitAndLoss < 0 }
        return PerformanceCalculator(records: losingRecords)
    }
    
    var summary: TradeSummary {
        return TradeSummary(
            profitPercentage: calculator.calculateAverageProfitAndLossPercent() ?? 0,
            profitAmount: calculator.calculateAverageProfitAndLossAmount(from: records, year: selectedYear) ?? 0,
            holdingDays: calculator.calculateAverageHoldingPeriod(from: records, year: selectedYear),
            winRate: calculator.calculateWinRate(from: records, year: selectedYear) ?? 0,
            profitFactor: calculator.calculateProfitFactor() ?? 0,
            maxDrawdown: calculator.calculateMaximumDrawdown() ?? 0,
            riskRewardRatio: calculator.calculateAverageRiskRewardRatio() ?? 0
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("負け取引サマリー")
                    .font(.title2)
                    .fontWeight(.bold)
                HStack {
                    VStack(alignment: .leading) {
                        MetricView(label: "合計損益", value: calculator.calculateTotalProfitAndLoss(from: records, year: selectedYear).withComma(), unit: "円", iconName: "dollarsign.circle", color: .blue)
                        
                        MetricView(label: "平均保有日数", value: Int(summary.holdingDays).description, unit: "日", iconName: "calendar", color: .primary)
                        
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        MetricView(label: "平均損益額", value: Int(summary.profitAmount).withComma(), unit: "円", iconName: "banknote.fill", color: .blue)
                        MetricView(label: "平均%", value: String(format: "%.1f", summary.profitPercentage), unit: "%", iconName: "percent", color: .blue)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("ワースト取引トップ3")
                            .font(.headline)
                        Picker("表示形式", selection: $selectedSortType) {
                            ForEach(PerformanceTradeSortType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.vertical, 8)
                    }
                    
                    ForEach(worstTrades.indices, id: \.self) { index in
                        let record = worstTrades[index]
                        
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
                                            .lineLimit(1)
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
        case 0: // 1st Place
            return Color(red: 0.2, green: 0.2, blue: 0.8).opacity(0.2)
        case 1: // 2nd Place
            return Color(red: 0.4, green: 0.4, blue: 0.9).opacity(0.2)
        case 2: // 3rd Place
            return Color(red: 0.6, green: 0.6, blue: 1.0).opacity(0.2)
        default: // Below 3rd Place
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

#if DEBUG
#Preview {
    LosingTradesView(records: StockRecord.mockRecords.filter{ $0.profitAndLossParcent ?? 0.0 < 0.0}, selectedYear: 2026)
}
#endif
