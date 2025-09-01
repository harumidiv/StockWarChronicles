//
//  EditView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/01.
//

import SwiftUI
import SwiftData

// 編集画面
struct EditView: View {
    @Bindable var record: StockRecord

    var body: some View {
        StockFormView(
            code: $record.code,
            market: $record.market,
            name: $record.name,
            date: $record.purchase.date,
            amountText: Binding(
                get: { String(record.purchase.amount) },
                set: { record.purchase.amount = Double($0) ?? 0 }
            ),
            sharesText: Binding(
                get: { String(record.purchase.shares) },
                set: { record.purchase.shares = Int($0) ?? 0 }
            ),
            reason: $record.purchase.reason,
            selectedTags: Binding(
                get: { record.tags.map { .init(name: $0.name, color: $0.color) } },
                set: { newTags in
                    record.tags = newTags.map { Tag(categoryTag: $0) }
                }
            )
        )
    }
}


#Preview {
    EditView(record: StockRecord.mockRecords.first!)
}
