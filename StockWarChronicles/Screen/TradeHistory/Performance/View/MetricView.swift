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
    let iconName: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .foregroundColor(.accentColor)
                .font(.title)
                .frame(width: 30, height: 30)
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
    MetricView(label: "Profit", value: "$123,456", iconName: "arrow.up.circle")
}
