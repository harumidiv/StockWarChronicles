//
//  TradeHistoryScreen.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/21.
//

import SwiftUI
import StoreKit

struct TradeHistoryScreen: View {
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
    @State private var showsCalendarSettings = false
    
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    
    // レビューダイアログ
    @AppStorage("reviewCount") var reviewCount: Int = 0
    @AppStorage("lastReviewVersion") var lastReviewVersion: String = ""
    @Environment(\.requestReview) private var requestReview
    
    var body: some View {
        NavigationStack {
            Group {
                switch historyType {
                case .calender:
                    HistoryCalendarView(selectedYear: $selectedYear)
                case .list:
                    HistoryListView(showTradeHistoryListScreen: $showTradeHistoryListScreen, selectedYear: $selectedYear)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                AdMobBannerView()
            }
            .onAppear {
                reviewCount += 1
                let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                if reviewCount >= 10, lastReviewVersion != currentVersion {
                    requestReview()
                    lastReviewVersion = currentVersion
                    reviewCount = 0
                }
            }
            .navigationTitle("取引記録")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Menu {
                        ForEach(HistoryType.allCases, id: \.self) { type in
                            Button {
                                historyType = type
                            } label: {
                                Label(type.rawValue, systemImage: type.imageName)
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Text("取引記録")
                            Image(systemName: "chevron.down")
                                .font(.caption2.weight(.semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button("dismiss", systemImage: "xmark") {
                        showTradeHistoryListScreen.toggle()
                    }
                }
                
                if historyType == .calender {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("カレンダー設定", systemImage: "slider.horizontal.3") {
                            showsCalendarSettings = true
                        }
                        .labelStyle(.iconOnly)
                    }
                    ToolbarSpacer(.fixed, placement: .topBarTrailing)
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
            .sheet(isPresented: $showsCalendarSettings) {
                HistoryCalendarSettingsView()
            }
            .navigationDestination(isPresented: $showAnnualPerformance) {
                AnnualPerformanceScreen(selectedYear: $selectedYear)
            }
        }
    }
}

#if DEBUG
#Preview {
    TradeHistoryScreen(showTradeHistoryListScreen: .constant(true))
}
#endif
