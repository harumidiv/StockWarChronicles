//
//  UIApplication+.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/04.
//

import UIKit

extension UIApplication {
    func closeKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
