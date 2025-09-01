//
//  EditScreen.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/01.
//

import SwiftUI
import SwiftData

// 編集画面
struct EditScreen: View {
    @Bindable var record: StockRecord
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
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
            .navigationTitle("編集")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("dismiss", systemImage: "xmark") {
                        dismiss()
                    }
                }
            }
        }
    }
}


#Preview {
    EditScreen(record: StockRecord.mockRecords.first!)
}
