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
    case profitAndLoss
    
    var title: String {
        switch self {
        case .date:
            return "日付順"
        case .holdingPeriod:
            return "保有日数順"
        case .fluctuationRate:
            return "損益率"
        case .profitAndLoss:
            return "損益額"
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
        case .profitAndLoss:
            return "yensign.circle"
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
    
    private var sortedRecords: [StockRecord] {
        switch currentSortType {
        case .date:
            return records.sorted { $0.purchase.date > $1.purchase.date }
            
        case .holdingPeriod:
            return records.sorted{ $0.holdingPeriod > $1.holdingPeriod}
      
        case .fluctuationRate:
            return records.sorted { $0.profitAndLossParcent ?? 0 > $1.profitAndLossParcent ?? 0 }
        case .profitAndLoss:
            return records.sorted { $0.profitAndLoss > $1.profitAndLoss }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedRecords) { record in
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
                                withAnimation {
                                    currentSortType = type
                                }
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

