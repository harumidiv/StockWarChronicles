//
//  StockWarChroniclesApp.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/19.
//

import SwiftUI
import SwiftData

@Model
final class TSEStockInfo {
    var name: String
    var code: String

    init(name: String, code: String) {
        self.name = name
        self.code = code
    }
}

@main
struct StockWarChroniclesApp: App {
    private let apiClient = APIClient()
    
    var body: some Scene {
        WindowGroup {
            PossessionScreen()
                .modelContainer(for: [StockRecord.self, TSEStockInfo.self])
                .environment(\.locale, Locale(identifier: "ja_JP"))
                .overlay(
                    EnvironmentContextAccessor { context in
                        Task {
                            // TODO: 最後に取得した日付を保存しておいてそれからの経過期間で取得するかを決める
                            
                            let email = "harumi.hobby@gmail.com"
                            let password = "A7kL9mQ2R8sT"
                            
                            do {
                                let authClient = AuthClient(client: apiClient)
                                let stockClient = StockClient(client: apiClient)
                                
                                let refreshToken = try await authClient.fetchRefreshToken(mail: email, password: password)
                                let idToken = try await authClient.fetchIdToken(refreshToken: refreshToken)
                                
                                let stockList = try await stockClient.fetchListedInfo(idToken: idToken)
                                print(stockList.count)
                                
                                // 既存の TSEStockInfo を全削除してから新規保存
                                try? context.fetch(FetchDescriptor<TSEStockInfo>()).forEach { context.delete($0) }
                                
                                // 新規データを一括挿入
                                for info in stockList {
                                    let model = TSEStockInfo(name: info.companyName, code: info.code)
                                    context.insert(model)
                                }
                                
                                // まとめて保存
                                do {
                                    try context.save()
                                } catch {
                                    print("TSEStockInfo save failed: \(error)")
                                }
                                
                            } catch {
                                // NOP
                            }
                        }
                        return Color.clear
                    }
                )
        }
    }
}

/// A lightweight helper to expose ModelContext within view modifiers/overlays.
private struct EnvironmentContextAccessor<Content: View>: View {
    @Environment(\.modelContext) private var context
    let content: (ModelContext) -> Content
    
    init(_ content: @escaping (ModelContext) -> Content) {
        self.content = content
    }
    
    var body: some View {
        content(context)
    }
}
