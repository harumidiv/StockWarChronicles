import SwiftUI
//
//  StockRecordDetailView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/21.
//


struct StockRecordDetailView: View {
    let record: StockRecord
    var body: some View {
            Form {
                Section(header: Text("サマリー")) {
                    VStack(alignment: .leading, spacing: 8) {

                        HStack {
                            Text("損益")
                            Spacer()
                            Text(record.profitAndLoss.description + "円")
                                .fontWeight(.semibold)
                        }

                        HStack {
                            Text("保有日数")
                            Spacer()
                            Text("8日")
                        }

                        HStack {
                            Text("株数")
                            Spacer()
                            Text(record.purchase.shares.description + "株")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Text("騰落率 \(String(format: "%.1f", record.profitAndLossParcent ?? 0))％")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("8/16 ~ 8/21")
                            Spacer()
                            Text("300株 5%")
                        }
                        HStack {
                            Text("8/16 ~ 8/25")
                            Spacer()
                            Text("700株 15%")
                        }
                        HStack {
                            Text("8/16 ~ 10/5")
                            Spacer()
                            Text("100株 50%")
                        }
                    }
                }

                Section(header: Text("購入根拠")) {
                    Text("上昇トレンド")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                }

                Section(header: Text("売却根拠")) {
                    Text("決算でコケた")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                }
            }
            .navigationTitle(record.code + " " + record.name)
        }
//    var body: some View {
//            ScrollView {
//                VStack(alignment: .leading, spacing: 16) {
//                    
//                    // 利益 & 保有日数
//                    VStack(alignment: .leading) {
//                        HStack {
//                            Text("損益")
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//                            Text("254,000円")
//                                .font(.title2)
//                                .fontWeight(.semibold)
//                        }
//                        
//                        HStack {
//                            Text("保有日数")
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//                            Text("8日")
//                                .font(.title2)
//                                .fontWeight(.semibold)
//                        }
//                        
//                        HStack {
//                            Text("保有株数")
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//                            Text("1000株")
//                                .font(.title2)
//                                .fontWeight(.semibold)
//                        }
//                    }
//                    
//                    VStack(alignment: .leading, spacing: 4) {
//                       
//                        Text("24%")
//                            .font(.title3)
//                            .fontWeight(.medium)
//                    }
//                    
//                    Divider()
//                    
//                    // 売却履歴
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("騰落率 \(String(format: "%.1f", record.profitAndLossParcent ?? 0))％")
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//                        
//                        VStack(alignment: .leading, spacing: 6) {
//                            Text("8/16 - 8/21   300株 = 5%")
//                            Text("8/16 - 8/25   700株 = 15%")
//                            Text("8/16 - 10/5   100株 = 50%")
//                        }
//                        .padding()
//                        .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4)))
//                    }
//                    
//                    // 購入根拠
//                    VStack(alignment: .leading, spacing: 4) {
//                        Text("購入根拠")
//                            .font(.headline)
//                        Text("上昇トレンド")
//                            .padding()
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4)))
//                    }
//                    
//                    // 売却根拠
//                    VStack(alignment: .leading, spacing: 4) {
//                        Text("売却根拠")
//                            .font(.headline)
//                        Text("決算でコケた")
//                            .padding()
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4)))
//                    }
//                    
//                    Spacer()
//                }
//                .padding()
//            }
//            .navigationTitle(record.code + " " + record.name)
//        }
}

#Preview {
    let purchase = StockTradeInfo(amount: 5000, shares: 100, date: Date(), reason: "成長期待")
    let sale = StockTradeInfo(amount: 6000, shares: 100, date: Date(), reason: "目標達成")
    let record = StockRecord(code: "140A", name: "ハッチ・ワーク", purchase: purchase, sales: [sale])
    StockRecordDetailView(record: record)
}

