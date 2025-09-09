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
        VStack(alignment: .leading, spacing: 24) {
            selectedTagView
            addTagView
            existingTagView
        }
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
    
    var editTagButton: some View {
        HStack {
            Spacer()
            
            Button {
                showTagEdit.toggle()
            } label: {
                Text("編集")
                    .font(.title3)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .foregroundColor(.primary)
                    .glassEffect()
                    .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
    }
    
    var selectedTagView: some View {
        // 選択済みのタグを表示
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .bottom) {
                Text("選択済みタグ")
                    .foregroundColor(.secondary)
                    .font(.caption)
                Spacer()
                editTagButton
            }
            
            ChipsView(tags: selectedTags) { tag in
                TagChipView(tag: tag, isSelected: selectedTags.contains(where: { $0.name == tag.name })) {
                    selectedTags.removeAll(where: { $0.name == tag.name })
                }
            } onTap: { tag in
                // onTapを使うと全てのタグが返却されてしまうので使わない
            }
            .padding(4)
            .background(.thinMaterial)
        }
        .padding(.bottom, 4)
    }
    
    var addTagView: some View {
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
    }
    
    var existingTagView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("既存タグ")
                .foregroundColor(.secondary)
                .font(.caption)

            ChipsView(tags: allTags) { tag in
                TagChipView(tag: tag, isSelected: selectedTags.contains(where: { $0.name == tag.name })) {
                    if selectedTags.contains(where: { $0.name == tag.name }) {
                        // 含まれている場合は削除
                        selectedTags.removeAll(where: { $0.name == tag.name })
                    } else {
                        // 含まれていない場合は追加
                        selectedTags.append(tag)
                    }
                }
            } onTap: { tag in
                // onTapを使うと全てのタグが返却されてしまうので使わない
            }
            .frame(minHeight: 28)
            .padding(4)
            .background(.thinMaterial)
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

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Tag.self, configurations: config)
    
    Tag.mockTags.forEach { tag in
        container.mainContext.insert(tag)
    }
    return TagSelectionView(selectedTags: .constant([Tag.mockTags.first!]))
        .modelContainer(container)
}
