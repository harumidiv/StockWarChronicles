//
//  TagSelectionView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/01.
//

import SwiftUI
import SwiftData

struct TagSelectionView: View {
    @Environment(\.modelContext) private var context
    
    @Query private var records: [StockRecord]
    
    @State private var newTagInput: String = ""
    @State private var selectedNewTagColor: Color = Color.randomPastel()
    
    private var allExistingTags: [Tag] {
        let uniqueTagNamesSet = Set(records.flatMap { $0.tags })
        return uniqueTagNamesSet.compactMap { $0 }
    }
    
    @Binding var selectedTags: [Tag]
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                
                Button {
                    // TODO: 編集画面に遷移させる
                    print("あああ")
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 22))
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
            }
            // 選択済みのタグを表示
            VStack(alignment: .leading, spacing: 8) {
                Text("選択済みタグ")
                    .font(.subheadline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedTags, id: \.name) { tag in
                            TagChipView(tag: tag, isSelected: true) {
                                selectedTags.removeAll(where: { $0.name == tag.name })
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 4)
            
            HStack(spacing: 8) {
                VStack(spacing: 4) {
                    TextField("新しいタグを追加", text: $newTagInput)
                        .textInputAutocapitalization(.never)
                    Divider()
                }
                
                ColorPicker("", selection: $selectedNewTagColor)
                    .labelsHidden()
                
                Button(action: addTag) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(newTagInput.isEmpty ? .gray : .accentColor)
                }
                .disabled(newTagInput.isEmpty || isDuplicateTag)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("既存タグ")
                    .font(.subheadline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(allExistingTags, id: \.name) { tag in
                            TagChipView(
                                tag: tag,
                                isSelected: selectedTags.contains(where: { $0.name == tag.name }),
                                onTap: {
                                    if selectedTags.contains(where: { $0.name == tag.name }) {
                                        selectedTags.removeAll(where: { $0.name == tag.name })
                                    } else {
                                        selectedTags.append(tag)
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    private var isDuplicateTag: Bool {
        let tagName = newTagInput.trimmingCharacters(in: .whitespaces)
        return allExistingTags.contains { $0.name == tagName }
    }
    
    private func addTag() {
        let tagName = newTagInput.trimmingCharacters(in: .whitespaces)
        guard !tagName.isEmpty else { return }
        
        // 既存のタグに同じ名前がないか確認
        let existingTag = allExistingTags.first(where: { $0.name == tagName })
        
        if let tag = existingTag {
            // 既存のタグが見つかった場合はそれを選択リストに追加
            if !selectedTags.contains(where: { $0.name == tag.name }) {
                selectedTags.append(tag)
            }
        } else {
            let tag = Tag(name: tagName, color: selectedNewTagColor)
            context.insert(tag)
            try? context.save()
            selectedTags.append(tag)
            
        }
        newTagInput = ""
    }
    
    struct TagChipView: View {
        let tag: Tag
        let isSelected: Bool
        let onTap: () -> Void

        var body: some View {
            HStack(spacing: 4) {
                Button(action: {
                    onTap()
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }) {
                    TagView(name: tag.name,
                            color: isSelected ? tag.color : Color.gray.opacity(0.2))
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Tag.self, configurations: config)
    
    Tag.mockTags.forEach { tag in
        container.mainContext.insert(tag)
    }
    return TagSelectionView(selectedTags: .constant([Tag.mockTags.first!]))
        .modelContainer(container)
}
