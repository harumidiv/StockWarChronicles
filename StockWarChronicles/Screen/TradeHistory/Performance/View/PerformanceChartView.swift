//
//  PerformanceChartView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/10/09.
//

import SwiftUI
import Charts

struct CumulativeChartPerformance: Identifiable {
    let id = UUID()
    let month: String
    let cumulativePerformance: Double
}

struct PerformanceChartView: View {
    enum ChartType: String, CaseIterable, Identifiable {
        case bar = "棒グラフ"
        case line = "折れ線グラフ"
        
        var id: String { self.rawValue }
    }

    let monthlyData: [MonthlyPerformance]
    
    @State private var selectedChartType: ChartType = .bar
    
    var body: some View {
        VStack {
            Picker("グラフの種類", selection: $selectedChartType) {
                ForEach(ChartType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            Group {
                switch selectedChartType {
                case .bar:
                    MonthlyPerformanceBarChart(monthlyData: monthlyData)
                        
                case .line:
                    MonthlyPerformanceLineChart(monthlyData: monthlyData)
                }
            }
        }
    }
}

struct MonthlyPerformanceBarChart: View {
    let monthlyData: [MonthlyPerformance]
    
    var body: some View {
        Chart {
            ForEach(monthlyData) { data in
                BarMark(
                    x: .value("月", data.month),
                    y: .value("成績", data.profitAmount)
                )
                .foregroundStyle(data.profitAmount >= 0 ? .green : .red)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                if let profit = value.as(Double.self) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        HStack(spacing: 0) {
                            let valueInManYen = profit / 10000
                            Text(valueInManYen, format: .number.precision(.fractionLength(0)).grouping(.automatic))
                                .font(.caption)
                            Text("万円")
                                .font(.caption)
                        }
                    }
                }
            }
        }
    }
}

import SwiftUI
import Charts

struct MonthlyPerformanceLineChart: View {
    // データモデルと累積計算のコードは省略
    let monthlyData: [MonthlyPerformance]
    
    private var cumulativeData: [CumulativeChartPerformance] {
        var cumulative: Double = 0
        return monthlyData.map { data in
            cumulative += data.profitAmount
            return CumulativeChartPerformance(month: data.month, cumulativePerformance: cumulative)
        }
    }

    var body: some View {
        Chart {
            ForEach(cumulativeData) { data in
                LineMark(
                    x: .value("月", data.month),
                    y: .value("合計成績", data.cumulativePerformance)
                )
                .symbol(.circle)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                if let profit = value.as(Double.self) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        HStack(spacing: 0) {
                            let valueInManYen = profit / 10000
                            Text(valueInManYen, format: .number.precision(.fractionLength(0)).grouping(.automatic))
                                .font(.caption)
                            Text("万円")
                                .font(.caption)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    let monthlyData: [MonthlyPerformance] = [
        .init(month: "1月", profitAmount: 5000),
        .init(month: "2月", profitAmount: -2000),
        .init(month: "3月", profitAmount: 8000),
        .init(month: "4月", profitAmount: 3000),
        .init(month: "5月", profitAmount: 10000),
        .init(month: "6月", profitAmount: -500),
        .init(month: "7月", profitAmount: 6000),
        .init(month: "8月", profitAmount: 1500),
        .init(month: "9月", profitAmount: 9000),
        .init(month: "10月", profitAmount: -3000),
        .init(month: "11月", profitAmount: 7000),
        .init(month: "12月", profitAmount: 4000)
    ]
    
    PerformanceChartView(monthlyData: monthlyData)
}

