//
//  MetricView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/06.
//

import SwiftUI

struct MetricView: View {
    let label: String
    let value: String
    let unit: String
    let iconName: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .foregroundColor(.primary)
                .font(.title)
                .frame(width: 30, height: 30)
            VStack(alignment: .leading) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 0) {
                    Text(value)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(color)
                    Text(unit)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    MetricView(label: "Profit", value: "123,456", unit: "円", iconName: "arrow.up.circle", color: .red)
}
