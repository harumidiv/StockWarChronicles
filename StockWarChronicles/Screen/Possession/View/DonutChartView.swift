//
//  DonutChartView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/10/20.
//


import SwiftUI
import Charts

struct DonutChartView: View {
    enum DisplayUnit: String, CaseIterable, Identifiable {
        case manYen
        case percent
        
        var id: String { rawValue }
        
        var label: String {
            switch self {
            case .manYen:
                return "万円"
            case .percent:
                return "%"
            }
        }
        
        /// 値の変換処理（元の値を単位に応じて変換）
        func convert(_ value: Double, total: Double? = nil) -> Double {
            switch self {
            case .manYen:
                return value
            case .percent:
                guard let total, total != 0 else { return 0 }
                return (value / total) * 100
            }
        }
    }
    
    let chartData: [PossesionChartData]
    @State private var displayUnit: DisplayUnit = .percent
    
    private var totalValue: Double {
        chartData.reduce(0) { $0 + $1.value }
    }
    
    var body: some View {
        Chart(chartData) { data in
            SectorMark(
                angle: .value("Value", data.value),
                innerRadius: .ratio(0.6),
                angularInset: 1.0
            )
            .foregroundStyle(data.color)
            .annotation(position: .overlay) {
                VStack(spacing: 0) {
                    Text(data.name)
                        .foregroundStyle(.primary)
                        .font(.subheadline)
                    
                    Text(String(Int(displayUnit.convert(data.value, total: totalValue))) + displayUnit.label)
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .bold()
                }
            }
        }
        .overlay {            
             Button(action: {
                 switch displayUnit {
                 case .manYen:
                     displayUnit = .percent
                 case .percent:
                     displayUnit = .manYen
                 }
             }) {
                 Image(systemName: displayUnit == .percent ?  "percent" : "yensign")
                     .font(.largeTitle)
                     .padding(12)
             }
             .glassButtonStyle()
        }
        .sensoryFeedback(.selection, trigger: displayUnit)
    }
}
