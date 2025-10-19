//
//  PossessionMapScreen.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/10/19.
//

import SwiftUI

struct PossessionMapScreen: View {
    let record: [StockRecord]
    
    var body: some View {
        VStack {
            Text("ポジション合計")
            Text(record.totalPurchaseValue().withComma())
            PossessionTreeMap(data: convertToTreeMapData(from: record))
        }
        .padding()
    }
    
    private func convertToTreeMapData(from records: [StockRecord]) -> [TreeMapData] {
        let groupedRecords = Dictionary(grouping: records, by: { $0.code })
        
        var result: [TreeMapData] = []
        
        for (code, records) in groupedRecords {
            // value の合計: purchase.amount × shares / 10000
            let totalValue = records.reduce(0.0) { partialResult, record in
                partialResult + (record.purchase.amount * Double(record.purchase.shares) / 10000)
            }
            
            // 名前は最初のレコードから取る（code は同じなので名前も同じ前提）
            if let firstRecord = records.first {
                let data = TreeMapData(code: code, name: firstRecord.name, value: totalValue)
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
    PossessionMapScreen(record: StockRecord.mockRecords)
}
