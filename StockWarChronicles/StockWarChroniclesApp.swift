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
            BootstrapperView(apiClient: apiClient) {
                PossessionScreen()
            }
            .modelContainer(for: [StockRecord.self, TSEStockInfo.self])
            .environment(\.locale, Locale(identifier: "ja_JP"))
        }
    }
}

/// ルートにぶら下げて、modelContext にアクセスしつつ .task で初期同期を行う薄いラッパー。
private struct BootstrapperView<Content: View>: View {
    @Environment(\.modelContext) private var context
    let apiClient: APIClient
    @ViewBuilder var content: () -> Content
    
    // 一度だけ実行するためのフラグ（再描画時の多重実行を防止）
    @State private var bootstrapped = false
    
    var body: some View {
        content()
            .task {
                guard !bootstrapped else { return }
                bootstrapped = true
                
                // TODO: 最後に取得した日付を保存しておいてそれからの経過期間で取得するかを決める
                let email = "harumi.hobby@gmail.com"
                let password = "A7kL9mQ2R8sT"
                
                do {
                    let authClient = AuthClient(client: apiClient)
                    let stockClient = StockClient(client: apiClient)
                    
                    let refreshToken = try await authClient.fetchRefreshToken(mail: email, password: password)
                    let idToken = try await authClient.fetchIdToken(refreshToken: refreshToken)
                    
                    let stockList = try await stockClient.fetchListedInfo(idToken: idToken)
                    
                    // 既存の TSEStockInfo を全削除してから新規保存
                    do {
                        let existing: [TSEStockInfo] = try context.fetch(FetchDescriptor<TSEStockInfo>())
                        existing.forEach { context.delete($0) }
                        try context.save()
                    } catch {
                        print("purge failed:", error.localizedDescription)
                    }
                    
                    // 新規データを一括挿入
                    for info in stockList {
                        // code を先頭4文字に丸める（4文字未満ならそのまま）
                        let trimmedCode = String(info.code.prefix(4))
                        let model = TSEStockInfo(name: info.companyName, code: trimmedCode)
                        context.insert(model)
                    }
                    
                    // まとめて保存
                    do {
                        try context.save()
                        print("insert save success")
                    } catch {
                        print("TSEStockInfo save failed: \(error)")
                    }
                    
                } catch {
                    // NOP（必要ならリトライやエラーハンドリングを実装）
                }
            }
    }
}
