//
//  Tag.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/19.
//

import SwiftUI
import SwiftData

@Model
final class Tag: Hashable, Identifiable {
    var id = UUID()
    var name: String
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

    func setColor(_ color: Color) {
        do {
            self.colorData = try NSKeyedArchiver.archivedData(withRootObject: UIColor(color), requiringSecureCoding: false)
        } catch {
            print("色の保存失敗")
        }
    }

    // Equatable / Hashable は id 基準で判定
    static func == (lhs: Tag, rhs: Tag) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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
