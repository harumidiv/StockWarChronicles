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
                    
                    Button(action: delete) {
                        Label("削除", systemImage: "trash")
                            .padding()
                            .border(.red)
                    }
                }
                .padding(.horizontal)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(editTags, id: \.name) { tag in
                            Button {
                                selectedTag = tag
                                originalName = tag.name
                                name = tag.name
                                color = tag.color
                            } label: {
                                TagView(
                                    name: tag.name,
                                    color: selectedTag?.name == tag.name
                                    ? tag.color
                                    : Color.gray.opacity(0.2)
                                )
                            }
                        }
                    }
                }
                Spacer()
            }
            .navigationTitle("タグ編集")
            .toolbar {
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        context.rollback()
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
                        })
                }
            }
            .onAppear {
                editTags = Array(records.flatMap { $0.tags }.unique())
            }
        }
    }
    
    // TOOD: 全てのRecordに登録されているタグが消えるのでアラートをつける
    func delete() {
        guard let deleteTagName = selectedTag?.name else {
            return
        }
        for record in records {
            record.tags.removeAll { $0.name == deleteTagName }
        }
        
        try? context.save()
        
        selectedTag = nil
        name = ""
        color = .blue
    }
    
    func save() {
        guard let tag = selectedTag else { return }
        
        tag.name = name
        tag.setColor(color: color)
        try? context.save()
        
        selectedTag = nil
        name = ""
        color = .blue
    }
}

#Preview {
    TagEditView()
}

