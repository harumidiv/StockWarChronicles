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
    @Binding var showTradeHistoryListScreen: Bool
    
    @Query private var records: [StockRecord]
    
    @State private var selectedRecord: StockRecord? = nil
    @State private var showDetail = false
    
    
    // Sort & Filter
    @State private var selectedTag: String = "すべて"
    @State private var currentSortType: SortType = .date
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    
    private var sortedRecords: [StockRecord] {
        var filteredRecords: [StockRecord] = records.filter {
            Calendar.current.component(.year, from: $0.purchase.date) == selectedYear
        }
        if selectedTag != "すべて" {
            filteredRecords = filteredRecords.filter { record in
                record.tags.contains { tag in
                    tag.name == selectedTag
                }
            }
        }
        
        switch currentSortType {
        case .date:
            return filteredRecords.sorted { $0.purchase.date > $1.purchase.date }
            
        case .holdingPeriod:
            return filteredRecords.sorted { $0.holdingPeriod > $1.holdingPeriod }
            
        case .fluctuationRate:
            return filteredRecords.sorted { ($0.profitAndLossParcent ?? 0) > ($1.profitAndLossParcent ?? 0) }
            
        case .profitAndLoss:
            return filteredRecords.sorted { $0.profitAndLoss > $1.profitAndLoss }
        }
    }
    
    private var availableYears: [Int] {
        let allDates = records.map { $0.purchase.date }
        let allYears = Set(allDates.map {
            Calendar.current.component(.year, from: $0)
        }).sorted(by: >)
        return allYears
    }
    
    private var allTags: [String] {
        let filteredRecords: [StockRecord] = records.filter {
            Calendar.current.component(.year, from: $0.purchase.date) == selectedYear
        }
        let uniqueTagNamesSet = Set(filteredRecords.flatMap { $0.tags }.map { $0.name })
        var uniqueTagNames = uniqueTagNamesSet.compactMap { $0 }
        uniqueTagNames.insert("すべて", at: 0)
        return uniqueTagNames
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                sortAndFilterView()
                
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
                        showTradeHistoryListScreen.toggle()
                    }
                }
            }
            .background(Color(.systemBackground))
        }
    }
    
    private func sortAndFilterView() -> some View {
        HStack {
            Spacer()
            Menu {
                ForEach(allTags, id: \.self) { tag in
                    Button(action: {
                        withAnimation {
                            self.selectedTag = tag
                        }
                    }) {
                        Text(tag)
                    }
                }
            } label: {
                HStack {
                    Text(selectedTag)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .fontWeight(.bold)
                }
            }
        
            Menu {
                ForEach(availableYears, id: \.self) { year in
                    Button(action: {
                        withAnimation {
                            self.selectedTag = "すべて"
                            self.selectedYear = year
                        }
                    }) {
                        Text("\(year)年")
                    }
                }
            } label: {
                HStack {
                    Text("\(String(describing: selectedYear))年")
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .fontWeight(.bold)
                }
            }
            
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
            }
        }
        .padding(.horizontal, 16)
    }
    
    private func stockRecordInfoCell(record: StockRecord) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(record.code + " " + record.name)
                    .font(.headline)
                Text("保有日数: \(record.holdingPeriod )日")
                    .font(.subheadline)
            }
            Spacer()
            if let percentage = record.profitAndLossParcent {
                VStack(alignment: .trailing, spacing: 8) {
                    Text(String(format: "%.1f", percentage) + "%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(percentage >= 0 ? .red : .blue)
                    
                    Text("\(record.profitAndLoss.withComma())円")
                        .fontWeight(.bold)
                        .foregroundColor(percentage >= 0 ? .red : .blue)
                }
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
            
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: StockRecord.self, configurations: config)
    
    StockRecord.mockRecords.forEach { record in
        container.mainContext.insert(record)
    }
    return TradeHistoryListScreen(showTradeHistoryListScreen: .constant(true))
        .modelContainer(container)
}

