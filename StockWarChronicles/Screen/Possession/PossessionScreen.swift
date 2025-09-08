//
//  PossessionScreen.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/19.
//

import SwiftUI
import SwiftData

struct PossessionScreen: View {
    @Namespace private var animation
    @Environment(\.modelContext) private var context
    @Query private var records: [StockRecord]
    
    @State private var showAddStockView: Bool = false
    @State private var showStockRecordView: Bool = false
    
    @State private var editingRecord: StockRecord?
    @State private var sellRecord: StockRecord?
    @State private var deleteRecord: StockRecord?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(records) { record in
                    if !record.isTradeFinish {
                        stockCell(record: record)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    context.delete(record)
                                    try? context.save()
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .tint(.red)
                                
                                Button {
                                    editingRecord = record
                                } label: {
                                    Image(systemName: "square.and.pencil")
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
                    .matchedTransitionSource(id: "add", in: animation)
                }
            }
            .sheet(isPresented: $showAddStockView) {
                AddScreen(showAddStockView: $showAddStockView)
                    .navigationTransition(.zoom(sourceID: "add", in: animation))
            }
            .sheet(item: $editingRecord) { record in
                EditScreen(record: record)
            }
            .sheet(item: $sellRecord) { record in
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
                        let generator = UIImpactFeedbackGenerator(style: .heavy)
                        generator.impactOccurred()
                    },
                    secondaryButton: .cancel(Text("キャンセル")) { }
                )
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
                
                HStack {
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
                            .foregroundColor(.green)
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
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: StockRecord.self, configurations: config)
    
    StockRecord.mockRecords.forEach { record in
        container.mainContext.insert(record)
    }
    
    return PossessionScreen()
        .modelContainer(container)
}
