//
//  AnnualPerformanceScreen.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/06.
//

import SwiftUI
import SwiftData

struct AnnualPerformanceScreen: View {
    @Query private var records: [StockRecord]
    @Binding var selectedYear: Int
    
    var filteredYearRecords: [StockRecord] {
        records
            .filter {
                $0.isTradeFinish
            }
            .filter {
                Calendar.current.component(.year, from: $0.purchase.date) == selectedYear
            }
    }
    
    var filteredWinRecords: [StockRecord] {
        filteredYearRecords.filter{ $0.profitAndLossParcent ?? 0.0 > 0.0}
    }
    
    var filteredLoseRecords: [StockRecord] {
        filteredYearRecords.filter{ $0.profitAndLossParcent ?? 0.0 < 0.0}
    }
    
    var body: some View {
        TabView {
            // MARK: - 全体タブ
            OverallPerformanceView(records: filteredYearRecords, selectedYear: $selectedYear)
                .tabItem {
                    Label("全体", systemImage: "chart.bar.fill")
                }
            
            // MARK: - 勝ち取引タブ
            WinningTradesView(records: filteredWinRecords)
                .tabItem {
                    Label("勝ち", systemImage: "arrow.up.right.circle.fill")
                }
            
            // MARK: - 負け取引タブ
            LosingTradesView(records: filteredLoseRecords)
                .tabItem {
                    Label("負け", systemImage: "arrow.down.right.circle.fill")
                }
        }
    }
    
    func calculateAverageProfitAndLossPercent(from records: [StockRecord]) -> Double {
        let percentages = records.compactMap { $0.profitAndLossParcent }
        
        guard !percentages.isEmpty else {
            return 0
        }
        let totalPercentage = percentages.reduce(0, +)
        return totalPercentage / Double(percentages.count)
    }
    
    func calculateWinRate(from records: [StockRecord]) -> Double {
        let winningTrades = records.filter { record in
            if let percentage = record.profitAndLossParcent {
                return percentage >= 0.0
            }
            return false
        }
        
        let totalTrades = Double(records.count)
        let numberOfWinningTrades = Double(winningTrades.count)
        let winRate = (numberOfWinningTrades / totalTrades) * 100
        
        return winRate
    }
    
    func calculateProfitFactor(from records: [StockRecord]) -> Double {
        let totalProfit = records.reduce(0.0) { (sum, record) in
            let profit = Double(record.profitAndLoss)
            return sum + (profit > 0 ? profit : 0.0)
        }
        
        let totalLoss = records.reduce(0.0) { (sum, record) in
            let loss = Double(record.profitAndLoss)
            return sum + (loss < 0 ? abs(loss) : 0.0)
        }
        
        if totalLoss == 0 {
            return totalProfit > 0 ? Double.infinity : 0
        }
        
        return totalProfit / totalLoss
    }
    
    func calculateMaximumDrawdown(from records: [StockRecord]) -> Double {
        var peakValue = 0.0 // 累積損益の最高値
        var drawdown = 0.0  // 現在のドローダウン
        var maxDrawdown = 0.0 // 記録された最大ドローダウン
        var accumulatedProfit = 0.0 // 累積損益
        
        // 2. 各レコードをループし、累積損益を計算しながらピークとドローダウンを追跡
        for record in records {
            // 累積損益を更新
            accumulatedProfit += Double(record.profitAndLoss)
            
            // 累積損益が新たなピークを更新したかチェック
            if accumulatedProfit > peakValue {
                peakValue = accumulatedProfit
            }
            
            // 現在のドローダウンを計算
            drawdown = (accumulatedProfit - peakValue) / peakValue * 100
            
            // 最大ドローダウンを更新
            if drawdown < maxDrawdown {
                maxDrawdown = drawdown
            }
        }
        
        return maxDrawdown
    }
    
    func calculateAverageProfitAndLossAmount(from records: [StockRecord]) -> Double {
        let totalProfitAndLossAmount = records.reduce(0.0) { (sum, record) in
            sum + Double(record.profitAndLoss)
        }
        
        let averageAmount = totalProfitAndLossAmount / Double(records.count)
        
        return averageAmount
    }
    
    func calculateAverageHoldingPeriod(from records: [StockRecord]) -> Double {
        let totalHoldingDays = records.reduce(0) { (sum, record) in
            sum + record.holdingPeriod
        }
        
        let averageDays = Double(totalHoldingDays) / Double(records.count)
        
        return averageDays
    }
    
    func calculateAverageRiskRewardRatio(from records: [StockRecord]) -> Double {
        let winningTrades = records.filter { $0.profitAndLoss >= 0 }
        let losingTrades = records.filter { $0.profitAndLoss < 0 }
        
        let averageProfit = winningTrades.isEmpty ? 0.0 : winningTrades.reduce(0.0) { $0 + Double($1.profitAndLoss) } / Double(winningTrades.count)
        
        // 5. 負け取引の平均損失額を計算（損失は正の値に変換）
        let averageLoss = losingTrades.isEmpty ? 0.0 : losingTrades.reduce(0.0) { $0 + abs(Double($1.profitAndLoss)) } / Double(losingTrades.count)
        
        // 6. 平均損失が0の場合は、nilを返す
        guard averageLoss != 0 else {
            return 0
        }
        
        // 7. 平均リスクリワードレシオを計算して返す
        return averageProfit / averageLoss
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: StockRecord.self, configurations: config)
    
    StockRecord.mockRecords.forEach { record in
        container.mainContext.insert(record)
    }
    
    return AnnualPerformanceScreen(selectedYear: .constant(2024))
        .modelContainer(container)
}
