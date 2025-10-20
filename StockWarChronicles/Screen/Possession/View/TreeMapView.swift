//
//  TreeMapView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/10/19.
//

import SwiftUI

struct TreeMapView: View {
    let treeMapData: [PossesionChartData]

    let ld: LayoutData
    
    var body: some View {
        if ld.direction == .h {
            HStack(spacing: 0.0) {
                VStack(spacing: 0.0) {
                    ForEach(0..<ld.content.count, id: \.self) { i in
                        Rectangle()
                            .foregroundColor(treeMapData[ld.content[i].index].color)
                            .frame(width: ld.content[i].w,
                                   height: ld.content[i].h)
                            .border(.primary, width: 0.5)
                            .overlay {
                                Text(treeMapData[ld.content[i].index].name)
                                    .padding(2)
                                    .minimumScaleFactor(0.3)
                            }
                    }
                }
                if let child = ld.child {
                    TreeMapView(treeMapData: treeMapData, ld: child)
                }
            }
        } else {
            VStack(spacing: 0.0) {
                HStack(spacing: 0.0) {
                    ForEach(0..<ld.content.count, id: \.self) { i in
                        Rectangle()
                            .foregroundColor(treeMapData[ld.content[i].index].color)
                            .frame(width: ld.content[i].w,
                                   height: ld.content[i].h)
                            .border(.primary, width: 0.5)
                            .overlay {
                                Text(treeMapData[ld.content[i].index].name)
                                    .padding(2)
                                    .minimumScaleFactor(0.3)
                            }
                    }
                }
                if let child = ld.child {
                    TreeMapView(treeMapData: treeMapData, ld: child)
                }
            }
        }
    }
}
