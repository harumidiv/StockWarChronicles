//
//  TradeHistoryListScreen.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/21.
//

import SwiftUI
import SwiftData

struct TradeHistoryListScreen: View {
    enum HistoryType: String, CaseIterable {
        case calender = "カレンダー"
        case list = "リスト"
    }
    
    @Binding var showTradeHistoryListScreen: Bool
    @State private var historyType: HistoryType = .calender
    @State private var showAnnualPerformance = false
    
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    
    var body: some View {
        NavigationStack {
            Group {
                HistoryListView(showTradeHistoryListScreen: $showTradeHistoryListScreen, selectedYear: $selectedYear)
            }
            .toolbarTitleMenu {
                ForEach(HistoryType.allCases, id: \.self) { type in
                    switch historyType {
                    case .calender:
                        Button(type.rawValue) {
                            historyType = .calender
                        }
                    case .list:
                        Button(type.rawValue) {
                            historyType = .list
                        }
                    }
                }
            }
            .navigationTitle("取引記録")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("dismiss", systemImage: "xmark") {
                        showTradeHistoryListScreen.toggle()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showAnnualPerformance.toggle()
                    }) {
                        HStack {
                            Image(systemName: "chart.pie")
                            Text("年間実績")
                        }
                    }
                }
            }
            .sensoryFeedback(.selection, trigger: showAnnualPerformance)
            .navigationDestination(isPresented: $showAnnualPerformance) {
                switch historyType {
                case .calender:
                    // TODO: 日付からとって渡す
                    AnnualPerformanceScreen(selectedYear: .constant(2025))
                case .list:
                    AnnualPerformanceScreen(selectedYear: $selectedYear)
                }
               
            }
        }
    }
}

#if DEBUG
#Preview {
    TradeHistoryListScreen(showTradeHistoryListScreen: .constant(true))
}
#endif
