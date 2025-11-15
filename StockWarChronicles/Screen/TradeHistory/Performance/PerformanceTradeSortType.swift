//
//  PerformanceTradeSortType.swift
//  StockWarChronicles
//
//  Created by Harumi Sagawa on 2025/11/15.
//

import Foundation

enum PerformanceTradeSortType: String, CaseIterable, Identifiable {
    case amount = "金額"
    case percent = "％"
    
    var id: String { rawValue }
}
