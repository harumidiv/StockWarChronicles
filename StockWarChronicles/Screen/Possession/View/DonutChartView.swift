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
        case shares
        
        var id: String { rawValue }
        
        var label: String {
            switch self {
            case .manYen:
                return "万円"
            case .percent:
                return "%"
            case .shares:
                return "株"
            }
        }
                
        var image: String {
            switch self {
            case .manYen:
                return "yensign"
            case .percent:
                return "percent"
            case .shares:
                return "square.stack.3d.down.right"
            }
        }
        
        /// 値の変換処理（元の値を単位に応じて変換）
        func convert(_ data: PossesionChartData, total: Double? = nil) -> Double {
            switch self {
            case .manYen:
                return data.value
            case .percent:
                guard let total, total != 0 else { return 0 }
                return (data.value / total) * 100
            case .shares:
                return Double(data.shares)
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
                    
                    Text(String(Int(displayUnit.convert(data, total: totalValue))) + displayUnit.label)
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
                     displayUnit = .shares
                 case .shares:
                     displayUnit = .manYen
                 }
             }) {
                 Image(systemName: displayUnit.image)
                     .font(.largeTitle)
                     .padding(12)
             }
             .glassButtonStyle()
        }
        .sensoryFeedback(.selection, trigger: displayUnit)
    }
}
