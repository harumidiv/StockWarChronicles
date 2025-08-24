//
//  Tag.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/19.
//

import SwiftUI
import SwiftData

@Model
final class Tag: Hashable {
    var name: String
    private var colorData: Data

    init(name: String, color: Color) {
        self.name = name
        self.colorData = try! NSKeyedArchiver.archivedData(withRootObject: UIColor(color), requiringSecureCoding: false)
    }
    
    init(categoryTag: CategoryTag) {
        self.name = categoryTag.name
        self.colorData = try! NSKeyedArchiver.archivedData(withRootObject: UIColor(categoryTag.color), requiringSecureCoding: false)
    }

    var color: Color {
        if let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .gray
    }
}

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
