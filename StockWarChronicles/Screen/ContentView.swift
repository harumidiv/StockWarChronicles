//
//  ContentView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/19.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        StockListView()
    }
}

import Charts

struct ChartData: Identifiable {
    let id = UUID()
    let time: Int
    let voltage: Int
}

#Preview {
    ContentView()
}
