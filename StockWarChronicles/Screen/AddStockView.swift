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
    @State private var market: Market = .tokyo
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
                        HStack {
                            TextField("銘柄コード", text: $code)
                            Picker("", selection: $market) {
                                ForEach(Market.allCases) { market in
                                    Text(market.rawValue)
                                        .tag(market)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        TextField("銘柄名", text: $name)
                        
                        DatePicker("購入日", selection: $purchaseDate, displayedComponents: .date)
                        
                        HStack {
                            TextField("購入額", text: $purchaseAmountText)
                                .keyboardType(.numberPad)
                            Text("円")
                            
                            TextField("株数", text: $sharesText)
                                .keyboardType(.numberPad)
                            Text("株")
                        }
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
                    
                    let isDisable = name.isEmpty || code.isEmpty || purchaseAmount == 0 || shares == 0
                    
                    Button(action: {
                        let tradeInfo = StockTradeInfo(amount: purchaseAmount, shares: shares, date: purchaseDate, reason: reason)
                        let stockRecord = StockRecord(code: code, market: market, name: name, purchase: tradeInfo, sales: [], tags: selectedTags.map { Tag(categoryTag: $0) })
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
                            .background(isDisable ? Color.gray : Color.blue)
                            .cornerRadius(10)
                    }
                    .padding()
                    .disabled(isDisable)
                }
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
                            TagChipView(name: tag.name, isSelected: true, color: tag.color, isDeletable: false) {
                                selectedTags.removeAll(where: { $0.name == tag.name })
                            }
                        }
                    }
                }
            }
            
            HStack {
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
                                color: tag.color,
                                isDeletable: true,
                            ) {
                                if selectedTags.contains(where: { $0.name == tag.name }) {
                                    selectedTags.removeAll(where: { $0.name == tag.name })
                                } else {
                                    // 既存のタグを選択
                                    selectedTags.append(tag)
                                }
                            } onDelete: {
                                print("delete call😺")
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
        let isDeletable: Bool
        let onTap: () -> Void
        var onDelete: (() -> Void)?

        var body: some View {
            HStack(spacing: 4) {
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

                if isDeletable {
                    Button(action: { onDelete?() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain) // 背景なし
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(
                Group {
                    if isDeletable {
                        Capsule()
                            .stroke(color, lineWidth: 1)
                    }
                }
            )
        }
    }
}
