//
//  TradeHistoryListScreen.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/21.
//


import SwiftUI
import SwiftData

import SwiftUI

enum SortType: CaseIterable, Identifiable {
    var id: Self { self }
    
    case date
    case holdingPeriod
    case fluctuationRate
    
    var title: String {
        switch self {
        case .date:
            return "日付順"
        case .holdingPeriod:
            return "保有日数が長い順"
        case .fluctuationRate:
            return "損益率"
        }
    }
    
    var systemName: String {
        switch self {
        case .date:
            return "calendar"
        case .holdingPeriod:
            return "timer"
        case .fluctuationRate:
            return "chart.bar"
        }
    }
}

struct TradeHistoryListScreen: View {
    @Binding var showStockRecordView: Bool
    
    // TODO: 年ごとに絞りたい
    @Query private var records: [StockRecord]
    
    @State private var selectedRecord: StockRecord? = nil
    @State private var showDetail = false
    
    @State private var currentSortType: SortType = .date
    
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
                ToolbarItem(placement: .topBarLeading) {
                    Button("dismiss", systemImage: "xmark") {
                        showStockRecordView.toggle()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(SortType.allCases) { type in
                            Button(action: {
                                currentSortType = type
                            }) {
                                Label(type.title, systemImage: type.systemName)
                            }
                        }
                    } label: {
                        HStack {
                            Text(currentSortType.title)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .padding(.vertical, 8)
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

