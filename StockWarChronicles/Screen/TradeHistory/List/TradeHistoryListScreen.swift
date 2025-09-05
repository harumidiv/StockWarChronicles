//
//  TradeHistoryListScreen.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/21.
//


import SwiftUI
import SwiftData

import SwiftUI

struct TradeHistoryListScreen: View {
    @Binding var showStockRecordView: Bool
    
    // TODO: 年ごとに絞りたい
    @Query private var records: [StockRecord]
    
    @State private var selectedRecord: StockRecord? = nil
    @State private var showDetail = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(records) { record in
                    if record.isTradeFinish {
                        Button {
                            selectedRecord = record
                            showDetail = true
                        } label: {
                            stockRecordInfoCell(record: record)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("取引記録")
            .navigationDestination(isPresented: $showDetail) {
                if let record = selectedRecord {
                    TradeHistoryDetailScreen(record: record)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("dismiss", systemImage: "xmark") {
                        showStockRecordView.toggle()
                    }
                }
                
            }
        }
    }
    
    private func stockRecordInfoCell(record: StockRecord) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(record.code + " " + record.name)
                    .font(.headline)
                HStack {
                    VStack(alignment: .leading) {
                        ForEach(record.sales) { sale in
                            HStack {
                                Text(record.purchase.date.formatted(as: .md))
                                    .font(.subheadline)
                                Text("-")
                                Text(sale.date.formatted(as: .md))
                                    .font(.subheadline)
                                
                                let purchaseAmount = record.purchase.amount * Double(sale.shares)
                                let salesAmount = sale.amount * Double(sale.shares)
                                let totalProfitAndLoss = salesAmount - purchaseAmount
                                let profitAndLossPercentage = (totalProfitAndLoss / purchaseAmount) * 100
                                
                                Text(String(format: "%.1f", profitAndLossPercentage) + "％")
                                    .font(.subheadline)
                                    .foregroundColor(profitAndLossPercentage >= 0 ? .red : .blue)
                            }
                        }
                    }
                }
            }
            Spacer()
            if let percentage = record.profitAndLossParcent {
                Text(String(format: "%.1f", percentage) + "%")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(percentage >= 0 ? .red : .blue)
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                    
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    TradeHistoryListScreen(showStockRecordView: .constant(true))
}
