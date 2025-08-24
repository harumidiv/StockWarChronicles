//
//  AddStockView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/19.
//

import SwiftUI
import SwiftData

struct AddStockView: View {
    @Environment(\.modelContext) private var context
    @Binding var showAddStockView: Bool
    
    @State private var code = ""
    @State private var name = ""
    @State private var purchaseDate = Date()
    @State private var purchaseAmountText = ""
    @State private var sharesText = ""
    @State private var newTagName = ""
    @State private var newTagColor: Color = .gray
    @State private var reason = ""
    
    @State private var selectedTags: [CategoryTag] = []
    
    var purchaseAmount: Double {
        Double(purchaseAmountText) ?? 0
    }
    var shares: Int {
        Int(sharesText) ?? 0
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section {
                        TextField("コード", text: $code)
                        TextField("名前", text: $name)
                        
                        DatePicker("購入日", selection: $purchaseDate, displayedComponents: .date)
                        
                        HStack {
                            TextField("購入額", text: $purchaseAmountText)
                                .keyboardType(.numberPad)
                            Text("円")
                        }
                        
                        TextField("株数", text: $sharesText)
                            .keyboardType(.numberPad)
                    }
                    
                    Section(header: Text("タグ")) {
                        TagSelectionView(selectedTags: $selectedTags)
                    }
                    
                    Section(header: Text("購入理由")) {
                        TextEditor(text: $reason)
                            .frame(height: 200)
                            .padding(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5))
                            )
                    }
                }
                
                Button(action: {
                    // TODO: 必須項目が欠けている場合に警告を出す
                    let tradeInfo = StockTradeInfo(amount: purchaseAmount, shares: shares, date: purchaseDate, reason: reason)
                    let stockRecord = StockRecord(code: code, name: name, purchase: tradeInfo, sales: [], tags: selectedTags.map { Tag(categoryTag: $0) })
                    context.insert(stockRecord)
                    
                    do {
                        try context.save()
                        showAddStockView.toggle()
                        
                    } catch {
                        // TODO: 失敗したらアラート
                        print("保存に失敗しました: \(error)")
                    }
                }) {
                    Text("追加")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
                .disabled(code.isEmpty || purchaseAmount == 0 || shares == 0)
                
            }
            .navigationTitle("追加")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("close", systemImage: "xmark") {
                        showAddStockView.toggle()
                    }
                }
            }
        }
    }
}

#Preview {
    AddStockView(showAddStockView: .constant(true))
}

struct TagSelectionView: View {
    @Environment(\.modelContext) private var context
    
    @Query private var allExistingTags: [CategoryTag]
    
    @State private var newTagInput: String = ""
    @State private var selectedNewTagColor: Color = .purple
    
    @Binding var selectedTags: [CategoryTag]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            // 選択済みのタグを表示
            VStack(alignment: .leading) {
                Text("選択済みのタグ")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedTags, id: \.name) { tag in
                            TagChipView(name: tag.name, isSelected: true, color: tag.color) {
                                selectedTags.removeAll(where: { $0.name == tag.name })
                            }
                        }
                    }
                }
            }
            
            // 新規タグ入力とColorPickerのエリア
            HStack {
                TextField("新しいタグを追加", text: $newTagInput)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                
                // ここにColorPickerを追加
                ColorPicker("", selection: $selectedNewTagColor)
                    .labelsHidden() // ラベルを非表示にする
                
                Button(action: addTag) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(newTagInput.isEmpty ? .gray : .accentColor)
                }
                .disabled(newTagInput.isEmpty)
            }
            
            // 既存タグリストの表示エリア
            VStack(alignment: .leading) {
                Text("既存タグ")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(allExistingTags, id: \.name) { tag in
                            TagChipView(
                                name: tag.name,
                                isSelected: selectedTags.contains(where: { $0.name == tag.name }),
                                color: tag.color
                            ) {
                                if selectedTags.contains(where: { $0.name == tag.name }) {
                                    selectedTags.removeAll(where: { $0.name == tag.name })
                                } else {
                                    // 既存のタグを選択
                                    selectedTags.append(tag)
                                }
                            }
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
        let name: String
        let isSelected: Bool
        let color: Color
        let onTap: () -> Void
        
        var body: some View {
            Button(action: onTap) {
                Text(name)
                    .font(.footnote)
                    .fontWeight(.bold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(isSelected ? color : Color.gray.opacity(0.2))
                    .foregroundColor(isSelected ? .white : .primary)
                    .clipShape(Capsule())
            }
        }
    }
}
