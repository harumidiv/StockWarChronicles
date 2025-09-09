//
//  Array+.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/09.
//

import Foundation

extension Array where Element: Hashable {
    func unique() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
