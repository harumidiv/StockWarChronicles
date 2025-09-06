//
//  PerformanceCalculator.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/06.
//

import Foundation

struct MonthlyPerformance {
    let month: String
    let profitAmount: Double
}

struct TradeSummary {
    let profitPercentage: Double
    let profitAmount: Double
    let holdingDays: Double
    let winRate: Double // 勝率
    let profitFactor: Double // プロフィットファクター
    let maxDrawdown: Double // 最大ドローダウン
    let riskRewardRatio: Double // リスクリワードレシオ
}

struct Trade {
    let title: String
    let profitAmount: Double
}

struct PerformanceCalculator {
    private let records: [StockRecord]

    init(records: [StockRecord]) {
        // 取引完了レコードのみを保持することで、以降の計算を効率化
        self.records = records.filter { $0.isTradeFinish }
    }

    // 平均損益%
    func calculateAverageProfitAndLossPercent() -> Double? {
        let percentages = records.compactMap { $0.profitAndLossParcent }
        guard !percentages.isEmpty else { return nil }
        return percentages.reduce(0, +) / Double(percentages.count)
    }

    // 勝率
    func calculateWinRate() -> Double? {
        guard !records.isEmpty else { return nil }
        let winningTradesCount = records.filter { ($0.profitAndLossParcent ?? -1) >= 0.0 }.count
        return (Double(winningTradesCount) / Double(records.count)) * 100
    }

    // プロフィットファクター
    func calculateProfitFactor() -> Double? {
        let totalProfit = records.reduce(0.0) { sum, record in
            sum + (Double(record.profitAndLoss) > 0 ? Double(record.profitAndLoss) : 0.0)
        }
        let totalLoss = records.reduce(0.0) { sum, record in
            sum + (Double(record.profitAndLoss) < 0 ? abs(Double(record.profitAndLoss)) : 0.0)
        }
        if totalLoss == 0 {
            return totalProfit > 0 ? .infinity : nil
        }
        return totalProfit / totalLoss
    }
    
    // 最大ドローダウン
    func calculateMaximumDrawdown() -> Double? {
        let sortedRecords = records.sorted { $0.purchase.date < $1.purchase.date }
        guard !sortedRecords.isEmpty else { return nil }

        var peakValue = 0.0
        var maxDrawdown = 0.0
        var accumulatedProfit = 0.0

        for record in sortedRecords {
            accumulatedProfit += Double(record.profitAndLoss)
            if accumulatedProfit > peakValue {
                peakValue = accumulatedProfit
            }
            let drawdown = (accumulatedProfit - peakValue)
            let drawdownPercent = (drawdown / abs(peakValue)) * 100
            if drawdownPercent < maxDrawdown {
                maxDrawdown = drawdownPercent
            }
        }
        return maxDrawdown
    }

    // 平均損益額
    func calculateAverageProfitAndLossAmount() -> Double? {
        guard !records.isEmpty else { return nil }
        let totalAmount = records.reduce(0.0) { sum, record in
            sum + Double(record.profitAndLoss)
        }
        return totalAmount / Double(records.count)
    }
    
    // 平均保有日数
    func calculateAverageHoldingPeriod() -> Double? {
        guard !records.isEmpty else { return nil }
        let totalDays = records.reduce(0) { sum, record in
            sum + record.holdingPeriod
        }
        return Double(totalDays) / Double(records.count)
    }
    
    // 平均リスクリワードレシオ
    func calculateAverageRiskRewardRatio() -> Double? {
        let winningTrades = records.filter { $0.profitAndLoss >= 0 }
        let losingTrades = records.filter { $0.profitAndLoss < 0 }

        let averageProfit = winningTrades.isEmpty ? 0.0 : winningTrades.reduce(0.0) { $0 + Double($1.profitAndLoss) } / Double(winningTrades.count)
        let averageLoss = losingTrades.isEmpty ? 0.0 : losingTrades.reduce(0.0) { $0 + abs(Double($1.profitAndLoss)) } / Double(losingTrades.count)

        guard averageLoss != 0 else {
            return averageProfit > 0 ? .infinity : nil
        }

        return averageProfit / averageLoss
    }
    
    // 月別損益
    func calculateMonthlyProfit() -> [MonthlyPerformance] {
        guard !records.isEmpty else { return [] }
        var monthlyProfits: [String: Double] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"

        for record in records.sorted(by: { $0.purchase.date < $1.purchase.date }) {
            let monthString = dateFormatter.string(from: record.purchase.date)
            monthlyProfits[monthString, default: 0.0] += Double(record.profitAndLoss)
        }

        let sortedKeys = monthlyProfits.keys.sorted()
        return sortedKeys.map { key in
            MonthlyPerformance(month: key, profitAmount: monthlyProfits[key] ?? 0.0)
        }
    }
    
    func calculateTotalProfitAndLoss(from records: [StockRecord]) -> Double {
        // 1. 取引が完了しているレコードのみをフィルタリング
        let finishedRecords = records.filter { $0.isTradeFinish }
        
        // 2. フィルタリングされたレコードの損益額をすべて合計
        let totalProfitAndLoss = finishedRecords.reduce(0.0) { sum, record in
            sum + Double(record.profitAndLoss)
        }
        
        // 3. 合計損益を返す
        return totalProfitAndLoss
    }
}
