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
    case amountAscending = "投資額の小さい順"
    case amountDescending = "投資額の大きい順"
    case unitPriceAscending = "取得単価の小さい順"
    case unitPriceDescending = "取得単価の大きい順"
    
    var id: Self { self }
}

private struct PositionRecordGroup: Identifiable {
    let id: String
    let records: [StockRecord]
}

private struct SellTarget: Identifiable {
    let id = UUID()
    let records: [StockRecord]
}

struct PossessionScreen: View {
    @Environment(\.modelContext) private var context
    @Query private var records: [StockRecord]
    
    @State private var showAddStockView: Bool = false
    @State private var showStockRecordView: Bool = false
    @State private var showTreeMapView: Bool = false
    
    @State private var editingRecord: StockRecord?
    @State private var sellTarget: SellTarget?
    @State private var deleteRecord: StockRecord?
    @AppStorage("combinesSameStockPositions") private var combinesSameStockPositions = true
    
    // Sort & Filter & Search
    @State private var selectedTag: Tag = .init(name: "すべてのタグ", color: .clear)
    @State private var currentSortType: PossessionSortType = .holdingPeriodAscending
    @State private var searchText: String = ""
    
    private var sortedRecords: [StockRecord] {
        
        var filteredRecords: [StockRecord] = records.filter {
            !$0.isTradeFinish
        }
        
        if !searchText.isEmpty {
            filteredRecords = filteredRecords.filter { record in
                let code = record.code.halfwidth.lowercased()
                let name = record.name.halfwidth.lowercased()
                let search = searchText.halfwidth.lowercased()
                let isCodeMatch = code.contains(search)
                let isNameMatch = name.contains(search)
                
                return isCodeMatch || isNameMatch
            }
        }
        
        if selectedTag.name != "すべてのタグ" {
            filteredRecords = filteredRecords.filter { record in
                record.tags.contains { tag in
                    tag.name == selectedTag.name
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
        case .unitPriceAscending:
            return filteredRecords.sorted { $0.purchase.amount < $1.purchase.amount }
        case .unitPriceDescending:
            return filteredRecords.sorted { $0.purchase.amount > $1.purchase.amount }
        }
    }
    
    private var allTags: [Tag] {
        let filteredRecords: [StockRecord] = records.filter {
            !$0.isTradeFinish
        }
        
        var seenNames = Set<String>()
        var uniqueTags = filteredRecords
            .flatMap { $0.tags }
            .filter { tag in
            seenNames.insert(tag.name).inserted
        }
        
        uniqueTags.insert(.init(name: "すべてのタグ", color: .clear), at: 0)
        return uniqueTags
    }

    /// ソート済みの並び順を保ったまま、同一市場・銘柄コード・ポジションの建玉を束ねます。
    private var groupedRecords: [PositionRecordGroup] {
        var groups: [PositionRecordGroup] = []
        var groupIndexes: [String: Int] = [:]

        for record in sortedRecords {
            let key = groupKey(for: record)
            if let index = groupIndexes[key] {
                let current = groups[index]
                groups[index] = PositionRecordGroup(id: current.id, records: current.records + [record])
            } else {
                groupIndexes[key] = groups.count
                groups.append(PositionRecordGroup(id: key, records: [record]))
            }
        }

        return groups
    }

    /// 保有リスト全体に、実際にまとめられる建玉があるかを判定します。
    private var hasCombinableRecords: Bool {
        var seenKeys = Set<String>()

        for record in records where !record.isTradeFinish {
            if !seenKeys.insert(groupKey(for: record)).inserted {
                return true
            }
        }

        return false
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if !sortedRecords.isEmpty {
                    sortAndFilterView()
                }
                List {
                    if combinesSameStockPositions {
                        ForEach(groupedRecords) { group in
                            if group.records.count > 1 {
                                groupedStockCell(records: group.records)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                            } else if let record = group.records.first {
                                stockCell(record: record)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        recordActions(for: record)
                                    }
                            }
                        }
                    } else {
                        ForEach(sortedRecords) { record in
                            stockCell(record: record)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    recordActions(for: record)
                                }
                        }
                    }
                }
                .sensoryFeedback(.selection, trigger: showStockRecordView)
                .sensoryFeedback(.selection, trigger: showTreeMapView)
                .sensoryFeedback(.selection, trigger: showAddStockView)
                .sensoryFeedback(.selection, trigger: sellTarget != nil)
                .sensoryFeedback(.selection, trigger: editingRecord)
                .listStyle(.plain)
                .navigationTitle("保有リスト")
                .toolbarTitleDisplayMode(.inline)
                .toolbar {
                    if !sortedRecords.isEmpty {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                showTreeMapView.toggle()
                            } label: {
                                Image(systemName: "square.grid.3x3.topleft.filled")
                            }
                        }
                    }
                    
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
                .fullScreenCover(item: $sellTarget) { target in
                    ClosingScreen(records: target.records)
                }
                .fullScreenCover(isPresented: $showStockRecordView) {
                    TradeHistoryScreen(showTradeHistoryListScreen: $showStockRecordView)
                }
                .fullScreenCover(isPresented: $showTreeMapView) {
                    PossessionMapScreen(record: records.filter {
                        !$0.isTradeFinish
                    }, showPossessionMapScreen: $showTreeMapView)
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
            .searchable(text: $searchText, prompt: "銘柄を検索")
        }
    }
    
    func stockCell(record: StockRecord) -> some View {
        Button {
            sellTarget = SellTarget(records: [record])
        } label: {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(record.position == .sell ? .blue : .red)
                    .frame(width: 5)
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
                                sellTarget = SellTarget(records: [record])
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
                    Rectangle()
                        .fill(Color(.tertiarySystemGroupedBackground))
                )
            }
        }
        .buttonStyle(.plain)
    }

    private func groupedStockCell(records: [StockRecord]) -> some View {
        let firstRecord = records[0]
        let totalRemainingShares = records.reduce(0) { $0 + $1.remainingShares }
        let totalPurchasedShares = records.reduce(0) { $0 + $1.purchase.shares }
        let weightedPurchaseAmount = totalRemainingShares == 0 ? 0 : records.reduce(0.0) {
            $0 + ($1.purchase.amount * Double($1.remainingShares))
        } / Double(totalRemainingShares)
        let oldestPurchaseDate = records.map(\.purchase.date).min() ?? firstRecord.purchase.date
        let allTags = uniqueTags(in: records)

        return Button {
            sellTarget = SellTarget(records: records)
        } label: {
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(Color(.tertiarySystemGroupedBackground).opacity(0.45))
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(firstRecord.position == .sell ? .blue : .red)
                            .frame(width: 5)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .offset(x: 6, y: 8)
                    .padding(.horizontal, 6)

                HStack(spacing: 0) {
                    Rectangle()
                        .fill(firstRecord.position == .sell ? .blue : .red)
                        .frame(width: 5)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(firstRecord.name)
                                .font(.headline)
                                .lineLimit(1)

                            Text("\(records.count)件")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.secondary.opacity(0.15), in: Capsule())

                            Spacer()

                            Text("平均 \(Int(weightedPurchaseAmount).withComma())円")
                                .font(.headline)
                        }

                        HStack {
                            Text(firstRecord.code)
                                .font(.subheadline)

                            Text(firstRecord.position.rawValue)
                                .font(.caption)
                                .foregroundStyle(firstRecord.position == .sell ? .blue : .red)

                            Spacer()

                            Text("合計 \(totalRemainingShares.withComma()) / \(totalPurchasedShares.withComma())株")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }

                        if !allTags.isEmpty {
                            ChipsView(tags: allTags) { tag in
                                TagView(name: tag.name, color: tag.color)
                            }
                        }

                        Divider()

                        HStack(spacing: 4) {
                            Image(systemName: "square.stack.3d.up.fill")
                            Text("\(oldestPurchaseDate.formatted(as: .yyyyMMdd))からの建玉をまとめて表示")
                                .lineLimit(1)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.bottom, 8)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(firstRecord.name)、\(firstRecord.position.rawValue)、\(records.count)件、合計\(totalRemainingShares)株")
        .accessibilityHint("まとめて手仕舞いする画面を開きます")
    }

    @ViewBuilder
    private func recordActions(for record: StockRecord) -> some View {
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

    private func groupKey(for record: StockRecord) -> String {
        let normalizedCode = record.code.halfwidth
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        return "\(record.market.rawValue)|\(normalizedCode)|\(record.position.rawValue)"
    }

    private func uniqueTags(in records: [StockRecord]) -> [Tag] {
        var seenNames = Set<String>()
        return records.flatMap(\.tags).filter { seenNames.insert($0.name).inserted }
    }

    private func sortAndFilterView() -> some View {
        VStack(spacing: 8) {
            if hasCombinableRecords {
                HStack {
                    Button {
                        withAnimation {
                            combinesSameStockPositions.toggle()
                        }
                    } label: {
                        Label(
                            "まとめて表示",
                            systemImage: combinesSameStockPositions ? "checkmark.square.fill" : "square"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    }
                    .sensoryFeedback(.selection, trigger: combinesSameStockPositions)

                    Spacer()
                }
            }

            HStack {
                Spacer()
                Menu {
                    ForEach(allTags, id: \.self) { tag in
                        Button(action: {
                            withAnimation {
                                self.selectedTag = tag
                            }
                        }) {
                            Label(tag.name, systemImage: "circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(tag.color)
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedTag.name)
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
