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
                Button (
                    action: {
                        showAmount.toggle()
                    },
                    label: {
                        HStack {
                            Text("ポジション合計")
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
                    .font(.title)
                
                Picker("Chart", selection: $chartType) {
                    ForEach(ChartType.allCases, id: \.self) { type in
                        switch type {
                        case .donatus:
                            Text("🍩ドーナッツ").tag(type)
                        case .treeMap:
                            Text("🌲ツリー").tag(type)
                        }
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .sensoryFeedback(.selection, trigger: chartType)
                
                switch chartType {
                case .donatus:
                    DonutChartView(chartData: convertToChartData(from: record))
                case .treeMap:
                    PossessionTreeMap(data: convertToChartData(from: record))
                }
            }
            .navigationTitle("保有資産構成")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("dismiss", systemImage: "xmark") {
                        showPossessionMapScreen.toggle()
                    }
                }
            }
        }
        .padding()
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
