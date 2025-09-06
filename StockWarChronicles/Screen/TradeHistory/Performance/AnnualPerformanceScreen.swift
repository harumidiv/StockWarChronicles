//
//  AnnualPerformanceScreen.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/06.
//


import SwiftUI
import SwiftData
import Charts

import Foundation

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
}


// データを保持するモデル
struct TradeSummary {
    let profitPercentage: Double
    let profitAmount: Double
    let holdingDays: Double
    let winRate: Double // 勝率
    let profitFactor: Double // プロフィットファクター
    let maxDrawdown: Double // 最大ドローダウン
    let riskRewardRatio: Double // リスクリワードレシオ
}

struct AnnualPerformance {
    let overall: TradeSummary
    let winningTrades: TradeSummary
    let losingTrades: TradeSummary
    let monthlyPerformance: [MonthlyPerformance] // 月別成績
    let bestTrades: [Trade] // ベスト取引
    let worstTrades: [Trade] // ワースト取引
}

struct MonthlyPerformance {
    let month: String
    let profitAmount: Double
}

struct Trade {
    let title: String
    let profitAmount: Double
}

// 画面全体のビュー
struct AnnualPerformanceScreen: View {
    @Query private var records: [StockRecord]
    let performance: AnnualPerformance
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

// MARK: - 各タブのビューコンポーネント

// 全体タブのビュー
struct OverallPerformanceView: View {
    let records: [StockRecord]
    @Binding var selectedYear: Int
    @State private var monthlyPerformance: [MonthlyPerformance] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("\(selectedYear)年 総合サマリー")
                    .font(.title2)
                    .fontWeight(.bold)
                // 主要なパフォーマンス指標のグリッド
                Grid(horizontalSpacing: 20, verticalSpacing: 20) {
                    GridRow {
                        MetricView(label: "平均%", value: String(format: "%.2f%%", calculateAverageProfitAndLossPercent(from: records)), iconName: "percent")
                        MetricView(label: "勝率", value: String(format: "%.2f%%", calculateWinRate(from: records)), iconName: "chart.pie.fill")
                    }
                    GridRow {
                        MetricView(label: "プロフィットファクター", value: String(format: "%.2f", calculateProfitFactor(from: records)), iconName: "gauge.simple.fill")
                        MetricView(label: "最大ドローダウン", value: String(format: "%.2f%%", calculateMaximumDrawdown(from: records)), iconName: "waveform.path.badge.minus")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // 月別損益グラフのプレースホルダー
                VStack(alignment: .leading) {
                    Text("月別損益推移")
                        .font(.headline)
                    
                    // ここにChartsフレームワークのChartビューを実装
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
                        Text(String(format: "%.0f円", calculateAverageProfitAndLossAmount(from: records)))
                            .fontWeight(.semibold)
                    }
                    GridRow {
                        Text("平均保有日数")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.1f日", calculateAverageHoldingPeriod(from: records)))
                            .fontWeight(.semibold)
                    }
                    GridRow {
                        Text("平均リスクリワードレシオ")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.2f", calculateAverageRiskRewardRatio(from: records)))
                            .fontWeight(.semibold)
                    }
                    
                    GridRow {
                        Text("総取引回数")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(records.count.description+"回")
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("全体パフォーマンス")
        .onAppear {
            monthlyPerformance = calculateMonthlyProfit(from: records)
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
    
    func calculateMonthlyProfit(from records: [StockRecord]) -> [MonthlyPerformance] {
        // 1. 取引完了レコードを時系列でソート
        let finishedRecords = records.filter { $0.isTradeFinish }.sorted { $0.purchase.date < $1.purchase.date }
        
        guard !finishedRecords.isEmpty else {
            return []
        }
        
        var monthlyProfits: [String: Double] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        
        // 2. 各取引の損益を月ごとに集計
        for record in finishedRecords {
            let monthString = dateFormatter.string(from: record.purchase.date)
            monthlyProfits[monthString, default: 0.0] += Double(record.profitAndLoss)
        }
        
        // 3. 辞書を時系列順の配列に変換
        let sortedKeys = monthlyProfits.keys.sorted()
        return sortedKeys.map { key in
            MonthlyPerformance(month: key, profitAmount: monthlyProfits[key] ?? 0.0)
        }
    }
}

// 勝ち取引タブのビュー
struct WinningTradesView: View {
    let records: [StockRecord]
    
    var body: some View {
        // ヘルパー構造体のインスタンスを作成
        let calculator = PerformanceCalculator(records: records)
        
        // 計算結果をViewで使用
        let summary = TradeSummary(
            profitPercentage: calculator.calculateAverageProfitAndLossPercent() ?? 0,
            profitAmount: calculator.calculateAverageProfitAndLossAmount() ?? 0,
            holdingDays: calculator.calculateAverageHoldingPeriod() ?? 0,
            winRate: calculator.calculateWinRate() ?? 0,
            profitFactor: calculator.calculateProfitFactor() ?? 0,
            maxDrawdown: calculator.calculateMaximumDrawdown() ?? 0,
            riskRewardRatio: calculator.calculateAverageRiskRewardRatio() ?? 0
        )
        
        let bestTrades = records
            .filter { $0.profitAndLoss >= 0 }
            .sorted { $0.profitAndLoss > $1.profitAndLoss }
            .map { Trade(title: $0.name, profitAmount: Double($0.profitAndLoss)) }
        
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("勝ち取引サマリー")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack {
                    HStack {
                        MetricView(label: "平均%", value: String(format: "%.2f%%", summary.profitPercentage), iconName: "percent")
                        Spacer()
                        MetricView(label: "平均損益額", value: String(format: "%.0f円", summary.profitAmount), iconName: "banknote.fill")
                    }
                    HStack {
                        MetricView(label: "平均保有日数", value: String(format: "%d日", Int(summary.holdingDays)), iconName: "calendar")
                        Spacer()
                        MetricView(label: "リスクリワード", value: String(format: "%.2f", summary.riskRewardRatio), iconName: "arrow.up.left.down.right.circle")
                    }
                }
                .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                                
                // ベスト取引のリスト
                VStack(alignment: .leading) {
                    Text("ベスト取引トップ3")
                        .font(.headline)
                    ForEach(bestTrades.prefix(3), id: \.title) { trade in
                        HStack {
                            Text(trade.title)
                            Spacer()
                            Text(String(format: "%.0f円", trade.profitAmount))
                                .foregroundColor(.green)
                                .fontWeight(.semibold)
                        }
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

// 負け取引タブのビュー
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

    var worstTrades: [Trade] {
        let losingRecords = records.filter { $0.profitAndLoss < 0 }
        return losingRecords
            .sorted { $0.profitAndLoss < $1.profitAndLoss }
            .map { Trade(title: $0.name, profitAmount: Double($0.profitAndLoss)) }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("負け取引サマリー")
                    .font(.title2)
                    .fontWeight(.bold)
                // 主要なパフォーマンス指標のグリッド
                Grid(horizontalSpacing: 20, verticalSpacing: 20) {
                    GridRow {
                        MetricView(label: "平均%", value: String(format: "%.2f%%", summary.profitPercentage), iconName: "percent")
                        MetricView(label: "平均損益額", value: String(format: "%.0f円", summary.profitAmount), iconName: "banknote.fill")
                    }
                    GridRow {
                        MetricView(label: "平均保有日数", value: String(format: "%.1f日", summary.holdingDays), iconName: "calendar")
                        MetricView(label: "リスクリワード", value: String(format: "%.2f", summary.riskRewardRatio), iconName: "arrow.up.left.down.right.circle")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // ワースト取引のリスト
                VStack(alignment: .leading) {
                    Text("ワースト取引トップ3")
                        .font(.headline)
                    ForEach(worstTrades.prefix(3), id: \.title) { trade in
                        HStack {
                            Text(trade.title)
                            Spacer()
                            Text(String(format: "%.0f円", trade.profitAmount))
                                .foregroundColor(.red)
                                .fontWeight(.semibold)
                        }
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

// 各指標（ラベル、値、アイコン）を共通化
struct MetricView: View {
    let label: String
    let value: String
    let iconName: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .foregroundColor(.accentColor)
                .font(.title)
            VStack(alignment: .leading) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: StockRecord.self, configurations: config)
    
    StockRecord.mockRecords.forEach { record in
        container.mainContext.insert(record)
    }
    
    return AnnualPerformanceScreen(performance: dummyPerformance, selectedYear: .constant(2024))
        .modelContainer(container)
}
