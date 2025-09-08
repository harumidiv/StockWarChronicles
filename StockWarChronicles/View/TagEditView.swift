//
//  TagEditView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/09.
//

import SwiftUI
import SwiftData

struct TagEditView: View {
    @Environment(\.modelContext) private var context
    @Query private var records: [StockRecord]
    
    private var allExistingTags: [Tag] {
        let uniqueTagNamesSet = Set(records.flatMap { $0.tags })
        return uniqueTagNamesSet.compactMap { $0 }
    }
    
    @State private var selectedTag: Tag?
    @State private var name: String = ""
    @State private var color: Color = .blue
    
    var body: some View {
        NavigationView {
            VStack {
                HStack(spacing: 8) {
                    VStack(spacing: 4) {
                        TextField("選択されたタグ名の編集", text: $name)
                            .textInputAutocapitalization(.never)
                        Divider()
                    }
                    
                    ColorPicker("", selection: $color)
                        .labelsHidden()
                    
                    Button(action: save) {
                        Label("保存", systemImage: "plus.circle.fill")
                            .padding()
                            .border(.red)
                    }
                    
                    Button(action: delete) {
                        Label("削除", systemImage: "trash")
                            .padding()
                            .border(.red)
                    }
                }
                .padding(.horizontal)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(allExistingTags, id: \.name) { tag in
                            HStack(spacing: 4) {
                                Button(action: {
                                    selectedTag = tag
                                    name = tag.name
                                    color = tag.color
                                }) {
                                    TagView(name: tag.name,
                                            color: selectedTag == tag ? tag.color : Color.gray.opacity(0.2))
                                }
                            }
                        }
                    }
                }
                Spacer()
            }
            .navigationTitle("タグ編集")
        }
    }
        
    func delete() {
        guard let deleteTagName = selectedTag?.name else {
            return
        }
        do {
            for record in records {
                record.tags.removeAll { $0.name == deleteTagName }
            }
            try context.save()
            
            selectedTag = nil
            name = ""
            color = .blue
            
        } catch {
            print("タグの削除中にエラーが発生しました: \(error)")
        }
    }
    
    func save() {
//        guard let selectedTag else { return }
//        selectedTag.name = name
//        selectedTag.color = color.cgColor.components!
//        try! context.save()
    }
}

#Preview {
    TagEditView()
}
