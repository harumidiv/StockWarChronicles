//
//  StockWarChroniclesApp.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/19.
//

import SwiftUI
import SwiftData

@main
struct StockWarChroniclesApp: App {
    var body: some Scene {
        WindowGroup {
            StockListView()
                .modelContainer(for: [StockRecord.self, CategoryTag.self])
                .environment(\.locale, Locale(identifier: "ja_JP"))
        }
    }
}
