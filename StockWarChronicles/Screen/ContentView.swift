//
//  ContentView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/19.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        StockListView()
    }
}

struct StockListView: View {
    @Namespace private var animation
    @Query private var records: [StockRecord]
    
    @State private var showAddStockView: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(records) { record in
                        VStack(alignment: .leading, spacing: 4) {
                            // 1行目: 名前 ＋ 金額
                            HStack {
                                Text(record.name)
                                    .font(.headline)
                                Spacer()
                                Text("\(Int(record.purchase.amount))円")
                            }
                            
                            // 2行目: コード ＋ 株数
                            HStack {
                                Text(record.code)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(record.purchase.shares)株")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
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
    ContentView()
}

