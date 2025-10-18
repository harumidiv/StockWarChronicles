//
//  PossessionTreeMap.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/10/19.
//

import SwiftUI

struct TreeMapData {
    let code: String
    let name: String
    let value: Double
}

final class LayoutData {
    enum Direction {
        case h
        case v
    }
    
    var direction: Direction = .h
    var content: [(index: Int, w: Double, h: Double)] = []
    var child: LayoutData? = nil
}

struct PossessionTreeMap: View {
    let data: [TreeMapData]
    
    var body: some View {
        GeometryReader { proxy in
            let ld = calculateLayout(
                w: proxy.size.width,
                h: proxy.size.height,
                data: data.map({ stock in
                    stock.value
                }),
                from: 0
            )
            
            TreeMapView(treeMapData: data, ld: ld)
                .border(.primary, width: 1) // 内側で隣接する辺が倍の太さになるので調整
        }
    }
    
    func calculateLayout(w: Double, h: Double, data: [Double], from: Int) -> LayoutData {
        let returnData = LayoutData()
        
        // Safety guards
        guard from < data.count, w.isFinite, h.isFinite, w > 0, h > 0 else {
            return returnData
        }
        
        // total remaining value
        let remainingSum = data[from...].reduce(0.0, +)
        guard remainingSum > 0, remainingSum.isFinite else {
            return returnData
        }
        
        // map area: how many points per value-unit
        let dataToArea = (w * h) / remainingSum
        
        returnData.direction = (w < h) ? .v : .h
        
        let mainLength = max(0.0001, min(w, h)) // avoid zero
        var currentIndex = from
        var area = data[currentIndex] * dataToArea
        area = max(0.0, area)
        var crossLength = area / mainLength
        crossLength = max(0.0, crossLength)
        
        var cellRatio = mainLength / max(0.0001, crossLength)
        cellRatio = max(cellRatio, 1.0 / cellRatio)
        
        while currentIndex + 1 < data.count {
            let newIndex = currentIndex + 1
            let newArea = area + data[newIndex] * dataToArea
            let newCrossLength = newArea / mainLength
            
            // protect from bad values
            if !(newCrossLength.isFinite && newCrossLength > 0) { break }
            
            var newCellRatio = (data[newIndex] * dataToArea) / (newCrossLength * newCrossLength)
            if !newCellRatio.isFinite { break }
            newCellRatio = max(newCellRatio, 1.0 / newCellRatio)
            
            if newCellRatio < cellRatio {
                currentIndex = newIndex
                area = newArea
                crossLength = newCrossLength
                cellRatio = newCellRatio
            } else {
                break
            }
        }
        
        // clamp crossLength to not exceed container
        if returnData.direction == .h {
            crossLength = min(crossLength, w)
        } else {
            crossLength = min(crossLength, h)
        }
        crossLength = max(0.0, crossLength)
        
        switch returnData.direction {
        case .h:
            for i in from...currentIndex {
                let itemArea = max(0.0, data[i] * dataToArea)
                let itemH = (crossLength > 0) ? (itemArea / crossLength) : 0.0
                returnData.content.append((index: i,
                                           w: crossLength,
                                           h: max(0.0, itemH)))
            }
        case .v:
            for i in from...currentIndex {
                let itemArea = max(0.0, data[i] * dataToArea)
                let itemW = (crossLength > 0) ? (itemArea / crossLength) : 0.0
                returnData.content.append((index: i,
                                           w: max(0.0, itemW),
                                           h: crossLength))
            }
        }
        
        // prepare remaining width/height for child; ensure non-negative
        if currentIndex != data.count - 1 {
            switch returnData.direction {
            case .h:
                let newW = max(0.0, w - crossLength)
                if newW > 0 {
                    returnData.child = calculateLayout(w: newW,
                                                       h: h,
                                                       data: data,
                                                       from: currentIndex + 1)
                }
            case .v:
                let newH = max(0.0, h - crossLength)
                if newH > 0 {
                    returnData.child = calculateLayout(w: w,
                                                       h: newH,
                                                       data: data,
                                                       from: currentIndex + 1)
                }
            }
        }
        
        return returnData
    }
}

#Preview {
    let mockData: [TreeMapData] = [
        TreeMapData(code: "7203", name: "トヨタ自動車", value: 580000),
        TreeMapData(code: "6758", name: "ソニーグループ", value: 420000),
        TreeMapData(code: "9984", name: "ソフトバンクグループ", value: 350000),
        TreeMapData(code: "9432", name: "日本電信電話 (NTT)", value: 260000),
        TreeMapData(code: "8058", name: "三菱商事", value: 300000),
        TreeMapData(code: "8306", name: "三菱UFJフィナンシャル・グループ", value: 180000),
        TreeMapData(code: "6752", name: "パナソニックホールディングス", value: 150000),
        TreeMapData(code: "6954", name: "ファナック", value: 200000),
        TreeMapData(code: "9983", name: "ファーストリテイリング", value: 400000),
        TreeMapData(code: "7974", name: "任天堂", value: 500000)
    ]
    PossessionTreeMap(data: mockData)
}
