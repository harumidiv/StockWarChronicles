//
//  Position.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/07.
//

import SwiftUI

enum Position: String, CaseIterable, Identifiable {
    case buy = "買い"
    case sell = "売り"
    
    var id: Self { self }
}
