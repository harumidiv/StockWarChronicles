//
//  Tag.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/19.
//

import SwiftUI
import SwiftData

struct Tag: Hashable, Identifiable, Codable {
    let id: UUID
    var name: String
    private var colorData: Data

    init(name: String, color: Color, id: UUID = UUID()) {
        self.id = id
        self.name = name
        colorData = try! NSKeyedArchiver.archivedData(withRootObject: UIColor(color), requiringSecureCoding: false)
    }

    var color: Color {
        if let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return .gray
    }

    // Equatable / Hashable は id 基準で判定
    static func == (lhs: Tag, rhs: Tag) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case colorData
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        colorData = try container.decode(Data.self, forKey: .colorData)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(colorData, forKey: .colorData)
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
