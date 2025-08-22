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
//        ChartView()
    }
}

import Charts

struct ChartData: Identifiable {
    let id = UUID()
    let time: Int
    let voltage: Int
}

struct ChartView: View {
    let data = [
        ChartData(time: 1, voltage: 100),
        ChartData(time: 2, voltage: 200),
        ChartData(time: 3, voltage: 150)
    ]

    var body: some View {
        Chart {
            ForEach(data) { datum in
                LineMark(x: .value("Time", datum.time),
                         y: .value("Voltage", datum.voltage))
                .opacity(0.4)
                if datum.time == 1 {
                    PointMark(x: .value("Time", datum.time),
                              y: .value("Voltage", datum.voltage))
                    .foregroundStyle(.green)  // 色を変えることもできるし
//                    .opacity(0.5)             // 透明度を変えることもできる
                } else {
                    PointMark(x: .value("Time", datum.time),
                              y: .value("Voltage", datum.voltage))
                    .foregroundStyle(.red)  // 色を変えることもできるし
//                    .opacity(0.5)             // 透明度を変えることもできる
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)  // たて軸を左側に表示
        }
        .chartXAxisLabel(position: .bottom, alignment: .center) {
            Text("Time [s]")
        }  // 軸ラベルをグラフの下側の左右中心に表示
        .chartYAxisLabel(position: .leading, alignment: .center, spacing: 0) {
            Text("Voltage [mV]")
        }  // 軸ラベルをグラフの左側の上下中央に表示し、周りの要素とのスペースをなくす
    }
}

#Preview {
    ContentView()
}
