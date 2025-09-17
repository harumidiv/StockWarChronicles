//
//  PossessionScreen.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/19.
//

import SwiftUI
import SwiftData

enum PossessionSortType: String, CaseIterable, Identifiable {
    case holdingPeriodAscending = "保有期間の短い順"
    case holdingPeriodDescending = "保有期間の長い順"
    case amountAscending = "ポジションの小さい順"
    case amountDescending = "ポジションの大きい順"
    
    var id: Self { self }
}

struct PossessionScreen: View {
    @Environment(\.modelContext) private var context
    @Query private var records: [StockRecord]
    
    @State private var showAddStockView: Bool = false
    @State private var showStockRecordView: Bool = false
    
    @State private var editingRecord: StockRecord?
    @State private var sellRecord: StockRecord?
    @State private var deleteRecord: StockRecord?
    
    // Sort & Filter
    @State private var selectedTag: String = "すべてのタグ"
    @State private var currentSortType: PossessionSortType = .holdingPeriodAscending

    private var sortedRecords: [StockRecord] {
        var filteredRecords: [StockRecord] = records.filter {
            !$0.isTradeFinish
        }
        
        if selectedTag != "すべてのタグ" {
            filteredRecords = filteredRecords.filter { record in
                record.tags.contains { tag in
                    tag.name == selectedTag
                }
            }
        }
        
        switch currentSortType {
        case .holdingPeriodAscending:
            return filteredRecords.sorted { $0.purchase.date > $1.purchase.date }
        case .holdingPeriodDescending:
            return filteredRecords.sorted { $0.purchase.date < $1.purchase.date }
        case .amountAscending:
            return filteredRecords.sorted { (Double($0.purchase.shares) * $0.purchase.amount) < (Double($1.purchase.shares) * $1.purchase.amount) }
        case .amountDescending:
            return filteredRecords.sorted { (Double($0.purchase.shares) * $0.purchase.amount) > (Double($1.purchase.shares) * $1.purchase.amount) }
        }
    }
    
    private var allTags: [String] {
        let filteredRecords: [StockRecord] = records.filter {
            !$0.isTradeFinish
        }
        let uniqueTagNamesSet = Set(filteredRecords.flatMap { $0.tags }.map { $0.name })
        var uniqueTagNames = uniqueTagNamesSet.compactMap { $0 }.sorted()
        uniqueTagNames.insert("すべてのタグ", at: 0)
        return uniqueTagNames
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if !sortedRecords.isEmpty {
                    sortAndFilterView()
                }
                List {
                    ForEach(sortedRecords) { record in
                        if !record.isTradeFinish {
                            stockCell(record: record)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        deleteRecord = record
                                    } label: {
                                        Label("削除", systemImage: "trash")
                                    }
                                    .tint(.red)
                                    
                                    Button {
                                        editingRecord = record
                                    } label: {
                                        Label("編集", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                }
                .sensoryFeedback(.selection, trigger: showStockRecordView)
                .sensoryFeedback(.selection, trigger: showAddStockView)
                .sensoryFeedback(.selection, trigger: sellRecord)
                .sensoryFeedback(.selection, trigger: editingRecord)
                .listStyle(.plain)
                .navigationTitle("保有リスト")
                .toolbar {
                    // 取引の完了しているデータがある場合履歴を表示
                    if records.contains(where: { $0.isTradeFinish }) {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showStockRecordView.toggle()
                            } label: {
                                Label("履歴", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    ToolbarItem(placement: .bottomBar) {
                        Button {
                            showAddStockView.toggle()
                        } label: {
                            Image(systemName: "plus")
                                .foregroundColor(.primary)
                                .padding()
                                .clipShape(Circle())
                        }
                        .frame(width: 60, height: 60)
                    }
                }
                .fullScreenCover(isPresented: $showAddStockView) {
                    AddScreen(showAddStockView: $showAddStockView)
                }
                .sheet(item: $editingRecord) { record in
                    EditScreen(record: record)
                }
                .fullScreenCover(item: $sellRecord) { record in
                    ClosingScreen(record: record)
                }
                .fullScreenCover(isPresented: $showStockRecordView) {
                    TradeHistoryListScreen(showTradeHistoryListScreen: $showStockRecordView)
                }
                .alert(item: $deleteRecord) { record in
                    Alert(
                        title: Text("本当に削除しますか？"),
                        message: Text("この株取引データは完全に削除されます。"),
                        primaryButton: .destructive(Text("削除")) {
                            context.delete(record)
                            try? context.save()
                            deleteRecord = nil
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        },
                        secondaryButton: .cancel(Text("キャンセル")) { }
                    )
                }
            }
        }
    }
    
    func stockCell(record: StockRecord) -> some View {
        Button {
            sellRecord = record
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(record.name)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    Text("\(Int(record.purchase.amount))円")
                        .font(.headline)
                }
                
                HStack {
                    Text(record.code)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(record.remainingShares) / \(record.purchase.shares)株")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if !record.tags.isEmpty {
                    ChipsView(tags: record.tags) { tag in
                        TagView(name: tag.name, color: tag.color)
                    }
                }
                
                Divider()
                
                HStack(spacing: 0) {
                    Text(record.purchase.date.formatted(as: .yyyyMMdd) + "〜")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(record.numberOfDaysHeld.description + "日")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Menu {
                        Button {
                            sellRecord = record
                        } label: {
                            Label("売却", systemImage: "cart")
                        }
                        Button {
                            editingRecord = record
                        } label: {
                            Label("編集", systemImage: "pencil")
                        }
                        
                        Divider()
                        Button(role: .destructive) {
                            deleteRecord = record
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .frame(width: 32, height: 24)
                            .foregroundColor(.primary)
                    }
                    .contentShape(Rectangle())
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.tertiarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
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
                .foregroundColor(.primary)
                .sensoryFeedback(.selection, trigger: selectedTag)
            }

            Menu {
                ForEach(PossessionSortType.allCases) { type in
                    Button(action: {
                        withAnimation {
                            currentSortType = type
                        }
                    }) {
                        Text(type.rawValue)
                    }
                }
            } label: {
                HStack {
                    Text(currentSortType.rawValue)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .foregroundColor(.primary)
                .sensoryFeedback(.selection, trigger: currentSortType)
            }
        }
        .padding(.horizontal, 16)
    }
}
#if DEBUG
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: StockRecord.self, configurations: config)
    
    StockRecord.mockRecords.forEach { record in
        container.mainContext.insert(record)
    }
    
    return PossessionScreen()
        .modelContainer(container)
}
#endif
