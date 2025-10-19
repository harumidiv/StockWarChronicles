//
//  PossessionMapScreen.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/10/19.
//

import SwiftUI
import Charts

// TODO: ツリーマップで左上にでかいのを配置するように修正する
// TODO: ドーナッツチャートを追加

struct PossessionMapScreen: View {
    enum ChartType: CaseIterable {
        case donatus
        case treeMap
    }
    
    let record: [StockRecord]
    @Binding var showPossessionMapScreen: Bool
    @State private var chartType: ChartType = .donatus
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
                
                switch chartType {
                case .donatus:
                    Spacer()
                    
                    DonutChartView(chartData: convertToChartData(from: record))
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
                let data = PossesionChartData(code: code, name: firstRecord.name, value: totalValue)
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


struct DonutChartView: View {
    let chartData: [PossesionChartData]
    
    private var totalValue: Double {
        chartData.reduce(0) { $0 + $1.value }
    }
    
    var body: some View {
        Chart(chartData) { data in
            SectorMark(
                angle: .value("Value", data.value), // 値
                innerRadius: .ratio(0.6), // 内側の半径 (0.6 = 60%)
                angularInset: 1.0 // セグメント間の隙間
            )
//            .foregroundStyle(data.color) // 色を指定
            .annotation(position: .overlay) {
                VStack {
                    Text(data.name)
                        .foregroundStyle(.primary)
                        .font(.caption)
                    
                    let percentage = (data.value / totalValue) * 100
                    Text("\(Int(percentage))%")
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .bold()
                }
            }
        }
    }
}
