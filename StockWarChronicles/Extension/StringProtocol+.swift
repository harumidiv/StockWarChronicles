//
//  StringProtocol+.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/14.
//

import Foundation

extension StringProtocol {
    var halfwidth: String {
        let string = self as! NSString
        return string.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? String(self)
    }
}
