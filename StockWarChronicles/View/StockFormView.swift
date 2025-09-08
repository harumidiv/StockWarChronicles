//
//  StockFormView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/01.
//

import SwiftUI
import SwiftData

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
    @Binding var selectedTags: [CategoryTag]
    
    @State var calendarId: UUID = UUID()
    
    var body: some View {
        Section(header: Text("銘柄情報")) {
            VStack {
                HStack {
                    Text("市場")
                    // Pickerは分離せずにTextの横に配置
                    Picker("", selection: $market) {
                        ForEach(Market.allCases) { market in
                            Text(market.rawValue).tag(market)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.green)
                    .sensoryFeedback(.selection, trigger: market)
                }
                
                Divider()
                    .background(.separator)
                    .padding(.bottom)
                
                HStack {
                    Text("銘柄コード")
                    TextField("(例)7203", text: $code)
                        .multilineTextAlignment(.trailing)
                }
                Divider()
                    .background(.separator)
                    .padding(.bottom)
                
                HStack {
                    Text("銘柄名")
                    TextField("(例)トヨタ自動車", text: $name)
                        .multilineTextAlignment(.trailing)
                }
                Divider().background(.separator)
            }
        }
        .listRowSeparator(.hidden)
        
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
                    
                    Picker("感情", selection: $emotion) {
                        ForEach(PurchaseEmotions.allCases) { emotion in
                            Text(emotion.rawValue + emotion.name)
                                .tag(Emotion.purchase(emotion))
                        }
                    }
                    .tint(.green)
                    .sensoryFeedback(.selection, trigger: emotion)

                    Divider().background(.separator)
                }
            }
            
            HStack {
                VStack {
                    DatePicker("日付", selection: $date, displayedComponents: .date)
                        .id(calendarId)
                        .onChange(of: date) { oldValue, newValue in
                            let calendar = Calendar.current
                            let oldDateWithoutTime = calendar.component(.day, from: oldValue)
                            let newDateWithoutTime = calendar.component(.day, from: newValue)
                            
                            if oldDateWithoutTime != newDateWithoutTime {
                                let generator = UISelectionFeedbackGenerator()
                                generator.selectionChanged()
                                calendarId = UUID()
                            }
                        }
                    Divider().background(.separator)
                }
            }
            
            HStack {
                VStack {
                    HStack {
                        TextField("金額", text: $amountText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
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
                        Text("株")
                    }
                    Divider().background(.separator)
                }
                .padding(.leading)
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
            }
            
        }
        .listRowSeparator(.hidden)
        
        Section(header: Text("タグ")) {
            TagSelectionView(selectedTags: $selectedTags)
        }
    }
}

#Preview {
    Form {
        StockFormView(
            code: .constant("7203"),
            market: .constant(.tokyo),
            name: .constant("トヨタ自動車"),
            date: .constant(Date()),
            position: .constant(.buy),
            amountText: .constant("200000"),
            sharesText: .constant("100"),
            emotion: .constant(Emotion.purchase(.random)
                              ),
            reason: .constant("長期投資のため"),
            selectedTags: .constant([
                CategoryTag(name: "自動車", color: .blue),
                CategoryTag(name: "大型株", color: .green)
            ])
        )
    }
}
