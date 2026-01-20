//
//  AnnualPerformanceScreen.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/06.
//

import SwiftUI
import SwiftData

struct AnnualPerformanceScreen: View {
    @Query private var records: [StockRecord]
    @Binding var selectedYear: Int
    
    @State private var selection = 0
    
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
        TabView(selection: $selection) {
            // MARK: - 全体タブ
            OverallPerformanceView(records: records, selectedYear: $selectedYear)
                .tabItem {
                    Label("全体", systemImage: "chart.bar.fill")
                }
                .tag(0)
            
            if !filteredWinRecords.isEmpty {
                // MARK: - 勝ち取引タブ
                WinningTradesView(records: filteredWinRecords, selectedYear: $selectedYear)
                    .tabItem {
                        Label("勝ち", systemImage: "arrow.up.right.circle.fill")
                    }
                    .tag(1)
            }
            
            if !filteredLoseRecords.isEmpty {
                // MARK: - 負け取引タブ
                LosingTradesView(records: filteredLoseRecords, selectedYear: $selectedYear)
                    .tabItem {
                        Label("負け", systemImage: "arrow.down.right.circle.fill")
                    }
                    .tag(2)
            }
        }
        .onChange(of: selection) { oldValue, newValue in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

#if DEBUG
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: StockRecord.self, configurations: config)
    
    StockRecord.mockRecords.forEach { record in
        container.mainContext.insert(record)
    }
    
    return AnnualPerformanceScreen(selectedYear: .constant(2024))
        .modelContainer(container)
}
#endif
