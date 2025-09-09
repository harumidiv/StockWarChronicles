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
    
    @State private var newTagName: String = ""
    @State private var selectedNewTagColor: Color = Color.randomPastel()
    
    
    @State private var allTags: [Tag] = []
    
    @Binding var selectedTags: [Tag]
    
    @State private var showTagEdit: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                
                Button {
                    showTagEdit.toggle()
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
                    TextField("新しいタグを追加", text: $newTagName)
                        .textInputAutocapitalization(.never)
                    Divider()
                }
                
                ColorPicker("", selection: $selectedNewTagColor)
                    .labelsHidden()
                
                Button(action: addTag) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(newTagName.isEmpty ? .gray : .accentColor)
                }
                .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("既存タグ")
                    .font(.subheadline)

                ChipsView(tags: allTags) { tag in
                    Button {
                        // selectedTagsに既にタグが含まれているか判定
                        if selectedTags.contains(where: { $0.name == tag.name }) {
                            // 含まれている場合は削除
                            selectedTags.removeAll(where: { $0.name == tag.name })
                        } else {
                            // 含まれていない場合は追加
                            selectedTags.append(tag)
                        }
                            
                    } label: {
                        TagView(
                            name: tag.name,
                            // 選択状態に応じて色を切り替える
                            color: selectedTags.contains(where: { $0.name == tag.name })
                                ? tag.color
                                : Color.gray.opacity(0.2)
                        )
                    }
                } onTap: { tag in
                    // onTapを使うと選択がバグるので使わない
                }
            }
        }
        .padding()
        .onAppear {
            allTags = Array(records.flatMap { $0.tags }.unique())
        }
        .onChange(of: showTagEdit) {
            if showTagEdit == false {
                allTags = Array(records.flatMap { $0.tags }.unique())
            }
        }
        .sheet(isPresented: $showTagEdit) {
            TagEditView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    private func addTag() {
        let tagName = newTagName.trimmingCharacters(in: .whitespaces)
        guard !tagName.isEmpty else { return }
        
        // 既存のタグに同じ名前がないか確認
        let existingTag = allTags.first(where: { $0.name == tagName })
        
        if let tag = existingTag {
            // 既存のタグが見つかった場合はそれを選択リストに追加
            if !selectedTags.contains(where: { $0.name == tag.name }) {
                selectedTags.append(tag)
            }
        } else {
            let newTag = Tag(name: tagName, color: selectedNewTagColor)
            selectedTags.append(newTag)
            
            // 既存タグ一覧も整合性を合わせるために追加
            if !allTags.contains(where: { $0.name == newTag.name }) {
                allTags.append(newTag)
            }
        }
        
        newTagName = ""
        selectedNewTagColor = Color.randomPastel()
        
    }
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
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Tag.self, configurations: config)
    
    Tag.mockTags.forEach { tag in
        container.mainContext.insert(tag)
    }
    return TagSelectionView(selectedTags: .constant([Tag.mockTags.first!]))
        .modelContainer(container)
}
