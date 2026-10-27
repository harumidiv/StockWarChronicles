//
//  PossessionMapScreen.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/10/19.
//

import SwiftUI
import Charts

struct PossessionMapScreen: View {
    enum ChartType: String, CaseIterable {
        case donatus = "🍩ドーナッツ"
        case treeMap = "🌲ツリー"
    }
    
    let record: [StockRecord]
    @Binding var showPossessionMapScreen: Bool
    
    @State private var chartType: ChartType = .donatus
    @State private var showAmount: Bool = true
    
    @State var screenshotMaker: ScreenshotMaker?
    
    var body: some View {
        NavigationView {
            VStack {
                dateView
                possessionTitalView
                
                Group {
                    switch chartType {
                    case .donatus:
                        DonutChartView(chartData: convertToChartData(from: record))
                    case .treeMap:
                        PossessionTreeMap(data: convertToChartData(from: record))
                    }
                }
                .padding(8)
            }
            .screenshotView { screenshotMaker in
               self.screenshotMaker = screenshotMaker
            }
            .toolbarTitleMenu {
                ForEach(ChartType.allCases, id: \.self) { chart in
                    switch chart {
                    case .donatus:
                        Button("🍩ドーナッツ") {
                            chartType = .donatus
                        }
                    case .treeMap:
                        Button("🌲ツリー") {
                            chartType = .treeMap
                        }
                    }
                }
            }
            .navigationTitle(chartType.rawValue)
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("dismiss", systemImage: "xmark") {
                        showPossessionMapScreen.toggle()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("share", systemImage: "square.and.arrow.up") {
                        shareScreenshot()
                    }
                }
            }
        }
        // iPhone Duo を開いたときなど横幅が広い画面でも2カラムにしない
        .navigationViewStyle(.stack)
        .padding()
    }
    
    var dateView: some View {
        HStack(spacing: 0) {
            Image("icon")
                .resizable()
                .scaledToFit()
                .frame(width: 40)
                .padding(.leading, 4)
            Text("かぶ戦記")
                .font(.title)
                .bold()
            VStack {
                HStack(alignment: .center) {
                    Spacer()
                    Text("保有株式")
                        .foregroundStyle(.primary)
                        .frame(width: 110)
                        .background(.secondary)
                }
                
                HStack {
                    Spacer()
                    Text(Date().formatted(as: .yy年MM月dd日))
                }
            }
            .padding()
        }
    }
    
    var possessionTitalView: some View {
        VStack(spacing: 0) {
            Button (
                action: {
                    showAmount.toggle()
                },
                label: {
                    HStack {
                        Text("運用総額")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Image(systemName: showAmount ? "eye" : "eye.slash")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20)
                            .foregroundColor(.primary)
                    }
                }
            )
            .sensoryFeedback(.selection, trigger: showAmount)
            
            let text = showAmount ? record.totalPurchaseValue().withComma() : "--------"
            Text(text + "円")
                .font(.largeTitle)
        }
    }
    
    private func convertToChartData(from records: [StockRecord]) -> [PossesionChartData] {
        let groupedRecords = Dictionary(grouping: records, by: { $0.code })
        
        var result: [PossesionChartData] = []
        
        for (code, records) in groupedRecords {
            // 残株数で集計（売却分を差し引く）
            let totalSharesValue: Int = records.reduce(0) { partialResult, record in
                let soldShares = record.sales.map { $0.shares }.reduce(0, +)
                let remaining = max(0, record.purchase.shares - soldShares)
                return partialResult + remaining
            }
            
            // value は購入単価 × 残株数 を万円単位に
            let totalValue: Double = records.reduce(0.0) { partialResult, record in
                let soldShares = record.sales.map { $0.shares }.reduce(0, +)
                let remaining = max(0, record.purchase.shares - soldShares)
                return partialResult + (record.purchase.amount * Double(remaining) / 10000)
            }
            
            // 名前は最初のレコードから取る（code は同じなので名前も同じ前提）
            if let firstRecord = records.first {
                let color = firstRecord.tags.isEmpty ? Color.randomPastel() : firstRecord.tags[0].color
                let data = PossesionChartData(code: code, name: firstRecord.name, shares: totalSharesValue, color: color, value: totalValue)
                result.append(data)
            }
        }
        
        return result
    }
    
    private func shareScreenshot() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController, let shareImage = screenshotMaker?.screenshot() {
            
            let activityVC = UIActivityViewController(activityItems: [shareImage], applicationActivities: nil)

            // 最前面のViewControllerを取得
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }

            // iPad対応（クラッシュ防止）
            activityVC.popoverPresentationController?.sourceView = topVC.view
            topVC.present(activityVC, animated: true)
        }
    }
}


private extension Array where Element == StockRecord {
    /// 保有ポジションの建値合計
    func totalPurchaseValue() -> Double {
        self.reduce(0.0) { partialResult, record in
            let soldShares = record.sales.map { $0.shares }.reduce(0, +)
            let remaining = Swift.max(0, record.purchase.shares - soldShares)
            return partialResult + (record.purchase.amount * Double(remaining))
        }
    }
}

#if DEBUG
#Preview {
    PossessionMapScreen(record: StockRecord.mockRecords, showPossessionMapScreen: .constant(true))
}
#endif

