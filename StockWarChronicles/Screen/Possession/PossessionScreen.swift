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
    
    var body: some View {
        NavigationView {
            List {
                ForEach(records) { record in
                    if !record.isTradeFinish {
                        stockCell(record: record)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                sellRecord = record
                            }
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
            .navigationTitle("保有リスト")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("record", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90") {
                        showStockRecordView.toggle()
                    }
                }
                
                ToolbarSpacer(.flexible, placement: .bottomBar)
                ToolbarItem(placement: .bottomBar) {
                    Button("add", systemImage: "plus") {
                        showAddStockView.toggle()
                    }
                }
                .matchedTransitionSource(id: "add", in: animation)
            }
            .sheet(isPresented: $showAddStockView) {
                AddScreen(showAddStockView: $showAddStockView)
                    .navigationTransition(.zoom(sourceID: "add", in: animation))
            }
            .sheet(item: $editingRecord) { record in
                EditScreen(record: record)
            }
            .sheet(item: $sellRecord) { record in
                SellScreen(record: record)
            }
            .fullScreenCover(isPresented: $showStockRecordView) {
                TradeHistoryScreen(showStockRecordView: $showStockRecordView)
            }
        }
    }
    
    func stockCell(record: StockRecord) -> some View {
        Section {
            VStack {
                HStack {
                    Text(record.name)
                        .font(.headline)
                    Spacer()
                    Text("\(Int(record.purchase.amount))円")
                }
                
                HStack {
                    
                    Text(record.code)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(record.remainingShares) / \(record.purchase.shares)株")
                        .font(.subheadline)
                }
                
                if !record.tags.isEmpty {
                    ChipsView(tags: record.tags) { tag in
                        TagView(name: tag.name, color: tag.color)
                    }
                }
                
                DashedLine(direction: .horizontal)
                
                HStack {
                    Text(record.purchase.date.formatted(as: .yyyyMMdd) + "〜")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("保有" + record.holdingPeriod.description + "日")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    
                    Menu {
                        Button(action: {
                            sellRecord = record
                        }) {
                            Label("売却", systemImage: "cart")
                        }
                        Button(action: {
                            editingRecord = record
                        }) {
                            Label("編集", systemImage: "pencil")
                        }
                        
                        Divider()
                        Button(role: .destructive, action: {
                            context.delete(record)
                            try? context.save()
                        }) {
                            Label("削除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.title3)
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                }
                .font(.caption)
            }
        }
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
