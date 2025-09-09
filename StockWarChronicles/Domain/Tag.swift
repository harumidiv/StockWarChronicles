//
//  Tag.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/19.
//

import SwiftUI
import SwiftData

@Model
final class Tag: Hashable, Equatable {
    var name: String
    private var colorData: Data

    init(name: String, color: Color) {
        self.name = name
        self.colorData = try! NSKeyedArchiver.archivedData(withRootObject: UIColor(color), requiringSecureCoding: false)
    }

    var color: Color {
        // Your color property implementation
        if let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .gray
    }
    
    func setColor(color: Color) {
        self.colorData = try! NSKeyedArchiver.archivedData(withRootObject: UIColor(color), requiringSecureCoding: false)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(colorData)
    }

    static func == (lhs: Tag, rhs: Tag) -> Bool {
        return lhs.name == rhs.name && lhs.colorData == rhs.colorData
    }
}

#if DEBUG
extension Tag {
    static var mockTags: [Tag] {
        [
            Tag(name: "長期保有", color: .blue),
            Tag(name: "成長株", color: .green),
            Tag(name: "損切り", color: .red),
            Tag(name: "高配当", color: .purple),
            Tag(name: "IPO", color: .orange)
        ]
    }
}
#endif
