//
//  StockInfoSectionView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/13.
//

import SwiftUI

struct StockInfoSectionView: View {
    @Binding var market: Market
    @Binding var code: String
    @Binding var name: String
    
    @FocusState.Binding var focusedField: StockFormFocusFields?
    
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
                    .tint(.primary)
                    .sensoryFeedback(.selection, trigger: market)
                }
                
                Divider()
                    .background(.separator)
                    .padding(.bottom)
                
                HStack {
                    Text("銘柄コード")
                    TextField("(例)7203", text: $code)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .code)
                        .onSubmit {
                            focusedField = .name
                        }
                }
                Divider()
                    .background(.separator)
                    .padding(.bottom)
                
                HStack {
                    Text("銘柄名")
                    TextField("(例)トヨタ自動車", text: $name)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .name)
                }
                Divider().background(.separator)
            }
        }
        .listRowSeparator(.hidden)
    }
}

private struct StockInfoSectionViewPreviewWrapper: View {
    @State var market: Market = .hukuoka
    @State var code: String = "1234"
    @State var name: String = "サンプル"
    @FocusState var focusedField: StockFormFocusFields?
    var body: some View {
        StockInfoSectionView(
            market: $market,
            code: $code,
            name: $name,
            focusedField: $focusedField
        )
    }
}

#Preview {
    StockInfoSectionViewPreviewWrapper()
}
