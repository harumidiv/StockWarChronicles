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
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(records) { record in
                        NavigationLink {
                            SellStockView(record: record)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(record.name)
                                        .font(.headline)
                                    Spacer()
                                    Text("\(Int(record.purchase.amount))円")
                                }
                                
                                HStack {
                                    Text(record.code)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(record.remainingShares)株")
                                        .foregroundColor(.secondary)
                                }
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
        }
    }
}

#Preview {
    StockListView()
}
