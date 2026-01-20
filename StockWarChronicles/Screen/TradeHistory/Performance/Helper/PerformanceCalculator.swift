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
}

struct Trade {
    let title: String
    let profitAmount: Double
}

struct PerformanceCalculator {
    private let records: [StockRecord]
    private let year: Int

    init(records: [StockRecord], year: Int) {
        self.records = records
        self.year = year
    }
}

// 総合サマリーのチャート計算
extension PerformanceCalculator {
    /// 月別のパフォーマンスを計算
    /// - Parameters:
    ///   - record: すべてのRecord
    ///   - year: 対象年
    /// - Returns: 月別パフォーマンス
    func calculateMonthlyProfit(from record: [StockRecord], year: Int) -> [MonthlyPerformance] {
        let calendar = Calendar.current
        var monthlyProfits: [Int: Double] = [:]
        
        let yearlyRecords = calculateTradeRecord(from: records, year: year)
        
        // 1. その年に売却が発生したレコードをループ
        for record in yearlyRecords {
            // その年の売却データのみ抽出
            let salesInYear = record.sales.filter { calendar.component(.year, from: $0.date) == year }
            
            for sale in salesInYear {
                let month = calendar.component(.month, from: sale.date)
                
                // この売却単体での損益を計算
                let saleAmount = Double(sale.shares) * sale.amount
                let cost = Double(sale.shares) * record.purchase.amount
                
                let profit = (record.position == .buy) ? (saleAmount - cost) : (cost - saleAmount)
                
                // 月ごとに加算
                monthlyProfits[month, default: 0.0] += profit
            }
        }
        
        // 2. 1月から12月までのデータを生成（取引がない月も0円として表示したい場合）
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateFormat = "M月"
        
        return (1...12).map { month in
            let dateComponents = DateComponents(year: year, month: month)
            let date = calendar.date(from: dateComponents)!
            let monthString = dateFormatter.string(from: date)
            
            return MonthlyPerformance(
                month: monthString,
                profitAmount: monthlyProfits[month] ?? 0.0
            )
        }
    }
}

// 総合サマリーのボード上にある６つの表記の計算メソッド
extension PerformanceCalculator {
    /// その年に確定した損益の合計を返す
    /// - Parameters:
    ///   - records: すべての取引履歴
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
    
    
    /// 平均保有日数の取得
    /// - Parameters:
    ///   - records: すべての取引履歴
    ///   - year: 対象年
    /// - Returns: 平均保有日数
    func calculateAverageHoldingPeriod(from records: [StockRecord], year: Int) -> Double {
        let calendar = Calendar.current
        
        // 1. その年に「最後の売却」が行われたレコードのみを抽出
        let targetRecords = records.filter { record in
            guard let lastSaleDate = record.sales.last?.date else { return false }
            return calendar.component(.year, from: lastSaleDate) == year
        }
        
        // 2. 対象レコードが空なら 0 を返す（ゼロ除算防止）
        guard !targetRecords.isEmpty else { return 0.0 }
        
        // 3. 対象レコードの保有日数を合計
        let totalDays = targetRecords.reduce(0) { sum, record in
            // すでに定義済みの holdingPeriod プロパティを利用
            // もし holdingPeriod が -1 を返す仕様なら、max(0, ...) で安全策をとる
            let period = record.holdingPeriod
            return sum + (period >= 0 ? period : 0)
        }
        
        // 4. 平均を算出
        return Double(totalDays) / Double(targetRecords.count)
    }
    
    
    /// 勝率を計算する
    /// - Parameter year: 対象年
    /// - Returns: 勝率
    func calculateWinRate(from records: [StockRecord], year: Int) -> Double? {
        // 1. その年に売却が発生したレコードのみを抽出
        let yearlyRecords = calculateTradeRecord(from: records, year: year)
        
        // 2. その年の取引がない場合は nil を返す
        guard !yearlyRecords.isEmpty else { return nil }
        
        // 3. その年の損益を計算し、プラス（またはゼロ）の銘柄をカウント
        let winningTradesCount = yearlyRecords.filter { record in
            // record 側のメソッドを呼び出すか、その場で見ている年の損益を計算
            (record.profitAndLossParcent ?? 0.0) >= 0.0
        }
        
        // 4. 勝率を計算（その年の勝ち数 / その年の取引銘柄数）
        return (Double(winningTradesCount.count) / Double(yearlyRecords.count)) * 100
    }
    
    
    /// 対象年のトレードを含むStockRecordを返す
    /// - Parameters:
    ///   - records: 全ての取引履歴
    ///   - year: 対象年
    /// - Returns: 取引のあったStockRecord
    func calculateTradeRecord(from records: [StockRecord], year: Int) -> [StockRecord] {
        let calendar = Calendar.current
        
        return records.filter { record in
            record.sales.contains { calendar.component(.year, from: $0.date) == year }
        }
    }
    
    
    /// 平均損益額を計算する
    /// - Parameters:
    ///   - records: 全ての取引履歴
    ///   - year: 対象年
    /// - Returns: 平均損益額
    func calculateAverageProfitAndLossAmount(from records: [StockRecord], year: Int) -> Double? {
        // 1. その年に売却が発生したレコードのみを抽出
        let yearlyRecords = calculateTradeRecord(from: records, year: year)
        
        // 取引がない場合は nil
        guard !yearlyRecords.isEmpty else { return nil }
        
        // 2. その年の損益額の合計を計算
        let totalProfitInYear = yearlyRecords.reduce(0.0) { sum, record in
            // その年の売却データのみを抽出して損益計算
            let calendar = Calendar.current
            let salesInYear = record.sales.filter { calendar.component(.year, from: $0.date) == year }
            let yearlySalesAmount = salesInYear.reduce(0.0) { $0 + (Double($1.shares) * $1.amount) }
            let yearlySoldShares = salesInYear.reduce(0) { $0 + $1.shares }
            let yearlyCost = Double(yearlySoldShares) * record.purchase.amount
            
            let profit = (record.position == .buy)
                ? (yearlySalesAmount - yearlyCost)
                : (yearlyCost - yearlySalesAmount)
            
            return sum + profit
        }
        
        // 3. その年の合計損益を、取引のあった銘柄数で割って平均を出す
        return totalProfitInYear / Double(yearlyRecords.count)
    }
    
    /// 平均損益%を計算する
    /// - Parameters:
    ///   - records: 全ての取引履歴
    ///   - year: 対象年
    /// - Returns: 平均損益率
    func calculateAverageProfitAndLossPercent(from records: [StockRecord], year: Int) -> Double? {
        // 1. その年に売却が発生したレコードのみを抽出
        let yearlyRecords = calculateTradeRecord(from: records, year: year)
        
        // 2. 取引がない場合は nil を返す
        guard !yearlyRecords.isEmpty else { return nil }
        
        // 3. 各レコードの「その年における損益率」を計算してリスト化
        let calendar = Calendar.current
        let percentages: [Double] = yearlyRecords.compactMap { record in
            let salesInYear = record.sales.filter { calendar.component(.year, from: $0.date) == year }
            
            // その年の売却額合計
            let yearlySalesAmount = salesInYear.reduce(0.0) { $0 + (Double($1.shares) * $1.amount) }
            // その年の売却株数に対する取得原価
            let yearlySoldShares = salesInYear.reduce(0) { $0 + $1.shares }
            let yearlyCost = Double(yearlySoldShares) * record.purchase.amount
            
            // 取得原価が0（異常データ）の場合はスキップ
            guard yearlyCost > 0 else { return nil }
            
            // 損益額の計算
            let profit = (record.position == .buy)
                ? (yearlySalesAmount - yearlyCost)
                : (yearlyCost - yearlySalesAmount)
            
            // その年だけの損益率(%)を算出
            return (profit / yearlyCost) * 100
        }
        
        // 4. パーセントの平均を算出
        guard !percentages.isEmpty else { return nil }
        return percentages.reduce(0.0, +) / Double(percentages.count)
    }
}
