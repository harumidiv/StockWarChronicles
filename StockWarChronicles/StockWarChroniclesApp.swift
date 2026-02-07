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

/// JQuantsの無料版に制限があるので最終読み込みから１ヶ月以上経っている場合銘柄コードので読み込みを行う
private struct BootstrapperView<Content: View>: View {
    @Environment(\.modelContext) private var context
    let apiClient: APIClient
    @ViewBuilder var content: () -> Content
    
    // 一度だけ実行するためのフラグ（再描画時の多重実行を防止）
    @State private var bootstrapped = false
    
    // 前回通信日時（UserDefaultsに保存）
    @AppStorage("lastListedInfoFetchDate") private var lastFetchISO8601: String = ""
    
    private var lastFetchDate: Date? {
        ISO8601DateFormatter().date(from: lastFetchISO8601)
    }
    
    private func shouldFetchNow(now: Date = Date()) -> Bool {
        // 初回（未保存）の場合は取得
        guard let last = lastFetchDate else { return true }
        // 1ヶ月以上経過しているか（カレンダーの月差で判定）
        let comps = Calendar.current.dateComponents([.month], from: last, to: now)
        if let months = comps.month, months >= 1 {
            return true
        }

        return false
    }
    
    private func updateLastFetchDate(to date: Date = Date()) {
        lastFetchISO8601 = ISO8601DateFormatter().string(from: date)
    }
    
    var body: some View {
        content()
            .task {
                guard !bootstrapped else { return }
                bootstrapped = true
                
                // 1ヶ月未満なら何もしない
                guard shouldFetchNow() else {
                    return
                }
                
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
                        // 成功したら最終取得日時を更新
                        updateLastFetchDate()
                    } catch {
                        print("TSEStockInfo save failed: \(error)")
                    }
                    
                } catch {
                    // 通信や認証で失敗した場合は日時更新しない
                }
            }
    }
}
