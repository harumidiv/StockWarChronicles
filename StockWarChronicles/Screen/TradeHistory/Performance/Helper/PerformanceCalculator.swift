//
//  PerformanceCalculator.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/06.
//

import Foundation

struct MonthlyPerformance: Identifiable {
    let id = UUID()
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
    func calculateAverageHoldingPeriod() -> Double {
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
        
        var monthlyProfits: [Int: Double] = [:]
        let calendar = Calendar.current
        
        for record in records.sorted(by: { $0.purchase.date < $1.purchase.date }) {
            let month = calendar.component(.month, from: record.purchase.date)
            monthlyProfits[month, default: 0.0] += Double(record.profitAndLoss)
        }
        
        let sortedMonths = monthlyProfits.keys.sorted()
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP")
        
        return sortedMonths.map { month in
            let dateComponents = DateComponents(month: month)
            let date = calendar.date(from: dateComponents)!
            dateFormatter.dateFormat = "M月"
            let monthString = dateFormatter.string(from: date)
            
            return MonthlyPerformance(month: monthString, profitAmount: monthlyProfits[month] ?? 0.0)
        }
    }
    
    
    
    /// その年に確定した損益の合計を返す
    /// - Parameters:
    ///   - records: 取引履歴
    ///   - year: 対象年
    /// - Returns: 損益
    func calculateTotalProfitAndLoss(from records: [StockRecord], year: Int) -> Double {
        let calendar = Calendar.current
        
        return records.reduce(0.0) { totalSum, record in
            // 1. その年に行われた売却(sales)だけを抽出
            let salesInYear = record.sales.filter { sale in
                calendar.component(.year, from: sale.date) == year
            }
            
            // 2. その年の売却額の合計を計算
            let yearlySalesAmount = salesInYear.reduce(0.0) { sum, sale in
                sum + (Double(sale.shares) * sale.amount)
            }
            
            // 3. その年に売却した株数に対する「購入原価」を計算
            let yearlySoldShares = salesInYear.reduce(0) { $0 + $1.shares }
            let yearlyCost = Double(yearlySoldShares) * record.purchase.amount
            
            // 4. ポジション（買い・売り）に応じて損益を算出
            let recordProfitAndLoss: Double
            switch record.position {
            case .buy:
                // 買い：売却額 - 原価
                recordProfitAndLoss = yearlySalesAmount - yearlyCost
            case .sell:
                // 売り：原価 - 売却額
                recordProfitAndLoss = yearlyCost - yearlySalesAmount
            }
            
            return totalSum + recordProfitAndLoss
        }
    }
}
