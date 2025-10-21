//
//  PossessionMapScreen.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/10/19.
//

import SwiftUI
import Charts

struct PossessionMapScreen: View {
    enum ChartType: CaseIterable {
        case donatus
        case treeMap
    }
    
    let record: [StockRecord]
    @Binding var showPossessionMapScreen: Bool
    
    @State private var chartType: ChartType = .donatus
    @State private var showAmount: Bool = true
    
    var body: some View {
        NavigationView {
            VStack {
                
                dateView
                
                possessionTitalView
                
                Picker("Chart", selection: $chartType) {
                    ForEach(ChartType.allCases, id: \.self) { type in
                        switch type {
                        case .donatus:
                            Text("🍩ドーナツ").tag(type)
                        case .treeMap:
                            Text("🌲ツリー").tag(type)
                        }
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding([.horizontal, .bottom])
                .sensoryFeedback(.selection, trigger: chartType)
                
                switch chartType {
                case .donatus:
                    DonutChartView(chartData: convertToChartData(from: record))
                case .treeMap:
                    PossessionTreeMap(data: convertToChartData(from: record))
                }
            }
            .navigationTitle("保有株構成")
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
        .padding()
    }
    
    var dateView: some View {
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
            // value の合計: purchase.amount × shares / 10000
            let totalValue = records.reduce(0.0) { partialResult, record in
                partialResult + (record.purchase.amount * Double(record.purchase.shares) / 10000)
            }
            
            // 名前は最初のレコードから取る（code は同じなので名前も同じ前提）
            if let firstRecord = records.first {
                let color = firstRecord.tags.isEmpty ? Color.randomPastel() : firstRecord.tags[0].color
                let data = PossesionChartData(code: code, name: firstRecord.name, color: color, value: totalValue)
                result.append(data)
            }
        }
        
        return result
    }
    
    private func shareScreenshot() {
        let image = self.snapshot()
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {

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
            partialResult + (record.purchase.amount * Double(record.purchase.shares))
        }
    }
}

#Preview {
    PossessionMapScreen(record: StockRecord.mockRecords, showPossessionMapScreen: .constant(true))
}
