//
//  TradeHistoryListScreen.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/21.
//

import SwiftUI

struct TradeHistoryListScreen: View {
    enum HistoryType: String, CaseIterable {
        case calender = "カレンダー"
        case list = "リスト"
        
        var imageName: String {
            switch self {
                
            case .calender:
                return "calendar"
            case .list:
                return "list.bullet"
            }
        }
    }
    
    @Binding var showTradeHistoryListScreen: Bool
    @State private var historyType: HistoryType = .calender
    @State private var showAnnualPerformance = false
    
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    
    var body: some View {
        NavigationStack {
            Group {
                switch historyType {
                case .calender:
                    HistoryCalendarView()
                case .list:
                    HistoryListView(showTradeHistoryListScreen: $showTradeHistoryListScreen, selectedYear: $selectedYear)
                }
            }
            .toolbarTitleMenu {
                ForEach(HistoryType.allCases, id: \.self) { type in
                    switch type {
                    case .calender:
                        Button(action: {
                            historyType = .calender
                        }) {
                            Label(type.rawValue, systemImage: type.imageName)
                        }

                    case .list:
                        Button(action: {
                            historyType = .list
                        }) {
                            Label(type.rawValue, systemImage: type.imageName)
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
                            Text("実績")
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
