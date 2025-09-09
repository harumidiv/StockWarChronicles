//
//  TagEditView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/09.
//

import SwiftUI
import SwiftData
import UIKit

struct TagEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var records: [StockRecord]
    
    @State private var editTags: [Tag] = []
    
    @State private var selectedTag: Tag?
    @State private var originalName: String = ""
    @State private var name: String = ""
    @State private var color: Color = .primary
    
    @State private var showDeleteAlert: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                Group {
                    if selectedTag != nil {
                        Text(name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .foregroundColor(color.isLight() ? .black : .white)
                            .background(color)
                            .lineLimit(1)
                            .clipShape(Capsule())
                    } else {
                        Spacer()
                    }
                }
                .frame(height: 70)
                
                
                HStack(spacing: 8) {
                    VStack(spacing: 4) {
                        TextField("選択されたタグ名の編集", text: $name)
                            .textInputAutocapitalization(.never)
                            .disabled(selectedTag == nil)
                        Divider()
                    }
                    
                    ColorPicker("", selection: $color)
                        .labelsHidden()
                        .disabled(selectedTag == nil)
                    
                    Button(action: {
                        showDeleteAlert.toggle()
                    }) {
                        Image(systemName: "trash.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(.red)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
                            .opacity(selectedTag == nil ? 0.2 : 1.0)
                    }
                    .disabled(selectedTag == nil)
                }
                .padding(.horizontal)
                ScrollView(.vertical, showsIndicators: false) {
                    ChipsView(tags: editTags) { tag in
                        TagView(
                            name: tag.name,
                            color: selectedTag?.name == tag.name
                            ? tag.color
                            : Color.gray.opacity(0.2)
                        )
                    } onTap: { tag in
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        if selectedTag == tag {
                            setup()
                        } else {
                            selectedTag = tag
                            originalName = tag.name
                            name = tag.name
                            color = tag.color
                        }
                    }
                }
                .padding()
                Spacer()
            }
            .padding()
            .navigationTitle("タグ編集")
            .toolbar {
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button (
                        action: {
                            save()
                        },
                        label: {
                            HStack {
                                Image(systemName: "externaldrive")
                                Text("保存")
                            }
                            .padding(.horizontal)
                            .opacity(name.isEmpty || selectedTag == nil ? 0.5 : 1.0)
                        })
                    .disabled(name.isEmpty || selectedTag == nil)
                }
            }
            .onAppear {
                editTags = Array(records.flatMap { $0.tags }.unique())
            }
            .alert("本当に削除しますか？", isPresented: $showDeleteAlert) {
                Button("削除", role: .destructive) {
                    delete()
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("全ての履歴からこのタグを削除します")
            }
        }
    }
    
    func delete() {
        for record in records {
            record.tags.removeAll { $0.name == originalName }
        }
        
        // 編集画面に表示しているものも整合性を合わせるために消す
        if let tagToRemove = selectedTag {
            editTags.removeAll { $0.name == tagToRemove.name }
        }
        
        try? context.save()
        
        setup()
    }
    
    func save() {
        guard let tag = selectedTag else { return }
        
        tag.name = name
        tag.setColor(color)
        try? context.save()
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        setup()
    }
    
    func setup() {
        selectedTag = nil
        name = ""
        originalName = ""
        color = .primary
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: StockRecord.self, configurations: config)
    
    StockRecord.mockRecords.forEach { record in
        container.mainContext.insert(record)
    }
    
    return TagEditView()
        .modelContainer(container)
    
}
