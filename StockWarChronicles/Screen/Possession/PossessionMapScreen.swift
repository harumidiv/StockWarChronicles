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
    
    enum DisplayUnit: String, CaseIterable, Identifiable {
        case manYen
        case percent
        
        var id: String { rawValue }
        
        var label: String {
            switch self {
            case .manYen:
                return "万円"
            case .percent:
                return "%"
            }
        }
        
        /// 値の変換処理（元の値を単位に応じて変換）
        func convert(_ value: Double, total: Double? = nil) -> Double {
            switch self {
            case .manYen:
                return value
            case .percent:
                guard let total, total != 0 else { return 0 }
                return (value / total) * 100
            }
        }
    }
    
    let record: [StockRecord]
    @Binding var showPossessionMapScreen: Bool
    
    @State private var chartType: ChartType = .donatus
    @State private var displayUnit: DisplayUnit = .manYen
    @State private var showTitalValue: Bool = true
    
    var body: some View {
        NavigationView {
            VStack {
                Button (
                    action: {
                        showTitalValue.toggle()
                    },
                    label: {
                        HStack {
                            Text("ポジション合計")
                                .foregroundColor(.primary)
                            Image(systemName: showTitalValue ? "eye" : "eye.slash")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20)
                                .foregroundColor(.primary)
                        }
                    })
                
                let text = showTitalValue ? record.totalPurchaseValue().withComma() : "--------"
                Text(text + "円")
                    .font(.title)
                
                
                HStack {
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
                    
                    Button (
                        action: {
                            switch displayUnit {
                            case .manYen:
                                displayUnit = .percent
                            case .percent:
                                displayUnit = .manYen
                            }
                        },
                        label: {
                            Image(systemName: displayUnit == .percent ? "percent" : "yensign")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 12)
                                .foregroundColor(.primary)
                        })
                        .glassEditButtonStyle()
                }
                .padding(.horizontal)
                
                switch chartType {
                case .donatus:
                    DonutChartView(chartData: convertToChartData(from: record), displayUnit: $displayUnit)
                case .treeMap:
                    PossessionTreeMap(data: convertToChartData(from: record))
                }
            }
            .navigationTitle("資産構成")
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
