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
    
    @Query private var allExistingTags: [CategoryTag]
    
    @State private var newTagInput: String = ""
    @State private var selectedNewTagColor: Color = .purple
    
    @Binding var selectedTags: [CategoryTag]
    
    var onDelete: ((CategoryTag) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading) {
            
            // 選択済みのタグを表示
            VStack(alignment: .leading, spacing: 8) {
                Text("選択済みのタグ")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedTags, id: \.name) { tag in
                            TagChipView(tag: tag, isSelected: true, isDeletable: false) {
                                selectedTags.removeAll(where: { $0.name == tag.name })
                            }
                        }
                    }
                }
            }
            
            HStack(spacing: 8) {
                TextField("新しいタグを追加", text: $newTagInput)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                
                ColorPicker("", selection: $selectedNewTagColor)
                    .labelsHidden()
                
                Button(action: addTag) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(newTagInput.isEmpty ? .gray : .accentColor)
                }
                .disabled(newTagInput.isEmpty)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("既存タグ")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(allExistingTags, id: \.name) { tag in
                            TagChipView(
                                tag: tag,
                                isSelected: selectedTags.contains(where: { $0.name == tag.name }),
                                isDeletable: true,
                                onTap: {
                                    if selectedTags.contains(where: { $0.name == tag.name }) {
                                        selectedTags.removeAll(where: { $0.name == tag.name })
                                    } else {
                                        selectedTags.append(tag)
                                    }
                                },
                                onDelete: { deleteTag in
                                    onDelete?(deleteTag)
                                }
                            )
                        }
                    }
                }
            }
        }
        .padding()
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
            let newCategoryTag = CategoryTag(name: tagName, color: selectedNewTagColor)
            context.insert(newCategoryTag)
            try? context.save()
            selectedTags.append(newCategoryTag)
            
        }
        newTagInput = ""
    }
    
    struct TagChipView: View {
        let tag: CategoryTag
        let isSelected: Bool
        let isDeletable: Bool
        let onTap: () -> Void
        var onDelete: ((CategoryTag) -> Void)?

        var body: some View {
            HStack(spacing: 4) {
                Button(action: onTap) {
                    Text(tag.name)
                        .font(.footnote)
                        .fontWeight(.bold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(isSelected ? tag.color : Color.gray.opacity(0.2))
                        .foregroundColor(isSelected ? .white : .primary)
                        .clipShape(Capsule())
                }

                if isDeletable {
                    Button(action: { onDelete?(tag) }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain) // 背景なし
                }
            }
            .padding(.horizontal, isDeletable ? 6 : 0)
            .padding(.vertical, isDeletable ? 4 : 0)
            .background(
                Group {
                    if isDeletable {
                        Capsule()
                            .stroke(tag.color, lineWidth: 1)
                    }
                }
            )
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: CategoryTag.self, configurations: config)
    
    CategoryTag.mockTags.forEach { tag in
        container.mainContext.insert(tag)
    }
    return TagSelectionView(selectedTags: .constant([CategoryTag.mockTags.first!]))
        .modelContainer(container)
}
