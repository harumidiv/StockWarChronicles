//
//  StockFormView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/01.
//

import SwiftUI
import SwiftData

enum StockFormFocusFields: Hashable {
    case code
    case name
    case amount
    case shares
    case memo
    case tag
    
    func next() -> StockFormFocusFields? {
        switch self {
        case .code: return .name
        case .name: return nil
        case .amount: return .shares
        case .shares: return .memo
        case .memo: return nil
        case .tag: return nil
        }
    }
}

struct StockFormView: View {
    @Binding var code: String
    @Binding var market: Market
    @Binding var name: String
    @Binding var date: Date
    @Binding var position: Position
    @Binding var amountText: String
    @Binding var sharesText: String
    @Binding var emotion: Emotion
    @Binding var reason: String
    @Binding var selectedTags: [Tag]
    
    @FocusState.Binding var focusedField: StockFormFocusFields?
    
    var body: some View {
        StockInfoSectionView(
            market: $market,
            code: $code,
            name: $name,
            focusedField: $focusedField
        )
        .id(StockFormFocusFields.name)
    
        tradeInfoSection
            .id(StockFormFocusFields.amount)
            .id(StockFormFocusFields.shares)
        
        TagSelectionView(selectedTags: $selectedTags)
            .focused($focusedField, equals: .tag)
            .id(StockFormFocusFields.tag)
        
    }
    
    var tradeInfoSection: some View {
        Section(header: Text("取引情報")) {
            Picker("ポジション", selection: $position) {
                ForEach(Position.allCases) { value in
                    Text(value.rawValue)
                        .tag(value)
                }
            }
            .pickerStyle(.segmented)
            .sensoryFeedback(.selection, trigger: position)
            
            HStack {
                VStack {
                    DatePickerAccordionView(date: $date)
                    Divider().background(.separator)
                }
            }
            
            HStack {
                VStack {
                    HStack {
                        TextField("金額", text: $amountText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .amount)
                            .onSubmit {
                                focusedField = .shares
                            }
                        Text("円")
                    }
                    Divider().background(.separator)
                }
                
                VStack {
                    HStack {
                        TextField(
                            "株数", text: $sharesText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .shares)
                        .onSubmit {
                            focusedField = .memo
                        }
                        Text("株")
                    }
                    Divider().background(.separator)
                }
                .padding(.leading)
            }
            
            HStack {
                VStack {
                    Picker("感情", selection: $emotion) {
                        ForEach(PurchaseEmotions.allCases) { emotion in
                            Text(emotion.rawValue + emotion.name)
                                .tag(Emotion.purchase(emotion))
                        }
                    }
                    .tint(.primary)
                    .sensoryFeedback(.selection, trigger: emotion)
                    
                    Divider().background(.separator)
                }
            }
            
            VStack {
                HStack {
                    Text("メモ")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                }
                TextEditor(text: $reason)
                    .frame(height: 80)
                    .padding(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.5))
                    )
                    .focused($focusedField, equals: .memo)
            }
        }
        .listRowSeparator(.hidden)
    }
}
#if DEBUG
#Preview {
    StockFormViewPreviewWrapper()
}

private struct StockFormViewPreviewWrapper: View {
    @FocusState private var focusedField: StockFormFocusFields?
    
    var body: some View {
        Form {
            StockFormView(
                code: .constant("7203"),
                market: .constant(.tokyo),
                name: .constant("トヨタ自動車"),
                date: .constant(Date()),
                position: .constant(.buy),
                amountText: .constant("200000"),
                sharesText: .constant("100"),
                emotion: .constant(Emotion.purchase(.random)),
                reason: .constant("長期投資のため"),
                selectedTags: .constant([
                    Tag(name: "自動車", color: .blue),
                    Tag(name: "大型株", color: .green)
                ]),
                focusedField: $focusedField
            )
        }
    }
}
#endif
