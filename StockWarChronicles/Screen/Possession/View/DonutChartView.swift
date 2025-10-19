//
//  DonutChartView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/10/20.
//


import SwiftUI
import Charts

struct DonutChartView: View {
    let chartData: [PossesionChartData]
    @Binding var displayUnit: PossessionMapScreen.DisplayUnit
    
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
                VStack {
                    Text(data.name)
                        .foregroundStyle(.primary)
                        .font(.caption)
                    
                    
                    Text(String(Int(displayUnit.convert(data.value, total: totalValue))) + displayUnit.label)
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .bold()
                }
            }
        }
    }
}
