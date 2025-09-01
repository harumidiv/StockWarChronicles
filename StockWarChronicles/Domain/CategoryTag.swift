//
//  CategoryTag.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/01.
//

import SwiftUI
import SwiftData

@Model
final class CategoryTag {
    @Attribute(.unique) var name: String
    private var colorData: Data

    init(name: String, color: Color) {
        self.name = name
        self.colorData = try! NSKeyedArchiver.archivedData(withRootObject: UIColor(color), requiringSecureCoding: false)
    }

    var color: Color {
        if let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .gray
    }
}

#if DEBUG
extension CategoryTag {
    static var mockTags: [CategoryTag] {
        [
            CategoryTag(name: "長期保有", color: .blue),
            CategoryTag(name: "成長株", color: .green),
            CategoryTag(name: "損切り", color: .red),
            CategoryTag(name: "高配当", color: .purple),
            CategoryTag(name: "IPO", color: .orange)
        ]
    }
}
#endif
