//
//  StockListView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/19.
//

import SwiftUI
import SwiftData

struct StockListView: View {
    @Namespace private var animation
    @Environment(\.modelContext) private var context
    @Query private var records: [StockRecord]
    
    @State private var showAddStockView: Bool = false
    @State private var showStockRecordView: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(records) { record in
                        if !record.isTradeFinish {
                            NavigationLink {
                                SellStockView(record: record)
                            } label: {
                                stockCell(record: record)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let record = records[index]
                            context.delete(record)
                        }
                        try? context.save()
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
                AddStockView(showAddStockView: $showAddStockView)
                    .navigationTransition(.zoom(sourceID: "add", in: animation))
            }
            .fullScreenCover(isPresented: $showStockRecordView) {
                StockRecordListView(showStockRecordView: $showStockRecordView)
            }
        }
    }
    
    func stockCell(record: StockRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(record.code)
                    .foregroundColor(.secondary)
                Text(record.name)
                    .font(.headline)
                Spacer()
                Text("\(Int(record.purchase.amount))円")
            }
            
            HStack {
                Text(record.purchase.date.formatted(as: .yyyyMMdd) + "〜")
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(record.remainingShares)株")
                    .foregroundColor(.secondary)
            }
            
            if !record.tags.isEmpty {
                DashedLine(direction: .horizontal)
                ChipsView(tags: record.tags) { tag in
                    let _ = print(tag.name)
                    Text(tag.name)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundColor(.white)
                        .background(tag.color)
                        .cornerRadius(8)
                }
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
    
    return StockListView()
        .modelContainer(container)
}
