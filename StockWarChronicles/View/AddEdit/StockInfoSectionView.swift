//
//  StockInfoSectionView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/13.
//

import SwiftUI
import SwiftData

struct CSVStockInfo: Identifiable, Decodable, Hashable {
    var id = UUID()
    let code: String
    let name: String
}

struct StockInfoSectionView: View {
    enum CandidateType {
        case name
        case code
    }
    
    @Binding var market: Market
    @Binding var code: String
    @Binding var name: String
    
    @Environment(\.modelContext) private var context
    @Query private var tseStocks: [TSEStockInfo]
    
    @State private var tokyoMarketStockData: [CSVStockInfo] = []
    @State private var selectedStock: CSVStockInfo?
    
    @FocusState.Binding var focusedField: StockFormFocusFields?
    
    var filteredCode: [CSVStockInfo] {
        if code.count <= 1 {
            return []
        }
        
        return tokyoMarketStockData.filter { stock in
            stock.code.hasPrefix(code)
        }
    }
    
    var filteredName: [CSVStockInfo] {
        if name.isEmpty {
            return []
        }
        
        // 💡 検索時に両方の文字列を小文字かつ半角に変換
        let searchTextHalfwidth = name.halfwidth.lowercased()
        
        return tokyoMarketStockData.filter { stock in
            let stockNameHalfwidth = stock.name.halfwidth.lowercased()
            
            return stockNameHalfwidth.hasPrefix(searchTextHalfwidth)
        }
    }
    
    var body: some View {
        Section(header: header) {
            VStack {
                HStack {
                    Text("市場")
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
                
                VStack {
                    HStack {
                        Text("銘柄コード")
                        TextField("(例)7203", text: $code)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .code)
                            .onSubmit {
                                focusedField = .name
                            }
                    }
                    if !filteredCode.isEmpty && !tokyoMarketStockData.contains(where: { $0.code == code && $0.name == name })  {
                        candidateView(csvStockInfoList: filteredCode, type: .code)
                    }
                }
                Divider()
                    .background(.separator)
                    .padding(.bottom)
                
                VStack {
                    HStack {
                        Text("銘柄名")
                        TextField("(例)トヨタ自動車", text: $name)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .name)
                    }
                    if !filteredName.isEmpty && !tokyoMarketStockData.contains(where: { $0.code == code && $0.name == name }) {
                        candidateView(csvStockInfoList: filteredName, type: .name)
                    }
                }
                Divider().background(.separator)
            }
        }
        .listRowSeparator(.hidden)
        .onAppear {
            if !tseStocks.isEmpty {
                // SwiftData のデータを優先して使用
                self.tokyoMarketStockData = tseStocks.map { CSVStockInfo(code: $0.code, name: $0.name) }
            } else if let stocks = readCSVFile(filename: "data_j") {
                self.tokyoMarketStockData = stocks
            }
        }
        // ここを復活: 保存完了後に自動で候補を更新
        .onChange(of: tseStocks) { _, newValue in
            if !newValue.isEmpty {
                self.tokyoMarketStockData = newValue.map { CSVStockInfo(code: $0.code, name: $0.name) }
            }
        }
    }
    @State private var showInfoEdit: Bool = false
    
    var header: some View {
        HStack {
            Text("銘柄情報")
            Spacer()
            
            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                showInfoEdit.toggle()
            } label: {
                Image(systemName: "info.circle")
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .popover(isPresented: $showInfoEdit) {
              Text("銘柄コード・銘柄名の予測検索は、東京証券取引所に上場する銘柄にのみに対応しています。")
                    .padding(.horizontal)
                    .font(.caption)
                .presentationCompactAdaptation(.popover)
            }
        }
    }
    
    private func candidateView(csvStockInfoList: [CSVStockInfo], type: CandidateType) -> some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(csvStockInfoList) { item in
                    Text(type == .code ? item.code : item.name)
                        .padding(8)
                        .onTapGesture {
                            code = item.code
                            name = item.name
                            focusedField = nil
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        }
                    Divider()
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .padding(.top, 4)
        }
    }
    
    private func readCSVFile(filename: String) -> [CSVStockInfo]? {
        guard let path = Bundle.main.path(forResource: filename, ofType: "csv") else {
            print("ファイルが見つかりません: \(filename).csv")
            return nil
        }
        
        do {
            let contents = try String(contentsOfFile: path, encoding: .utf8)
            let lines = contents.components(separatedBy: .newlines)
            
            var stockInfos: [CSVStockInfo] = []
            
            // ヘッダー行をスキップし、空行を無視する
            for (index, line) in lines.enumerated() where index > 0 && !line.isEmpty {
                let columns = line.components(separatedBy: ",")
                
                // 少なくとも2つの列があることを確認
                guard columns.count > 1 else {
                    continue
                }
                
                // 💡 二重引用符と空白、改行を取り除く
                let code = columns[1].trimmingCharacters(in: CharacterSet(charactersIn: "\" \n\r"))
                let name = columns[2].trimmingCharacters(in: CharacterSet(charactersIn: "\" \n\r"))
                
                let stockInfo = CSVStockInfo(code: code, name: name)
                stockInfos.append(stockInfo)
            }
            
            return stockInfos
        } catch {
            print("ファイルの読み込みに失敗しました: \(error)")
            return nil
        }
    }
}

private struct StockInfoSectionViewPreviewWrapper: View {
    @State var market: Market = .hukuoka
    @State var code: String = "12"
    @State var name: String = "サンプル"
    @FocusState var focusedField: StockFormFocusFields?
    var body: some View {
        Form {
            StockInfoSectionView(
                market: $market,
                code: $code,
                name: $name,
                focusedField: $focusedField
            )
        }
    }
}

#Preview {
    StockInfoSectionViewPreviewWrapper()
}
