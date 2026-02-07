//
//  StockWarChroniclesApp.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/08/19.
//

import SwiftUI
import SwiftData

@main
struct StockWarChroniclesApp: App {
    private let apiClient = APIClient()
    
    var body: some Scene {
        WindowGroup {
            PossessionScreen()
                .modelContainer(for: [StockRecord.self])
                .environment(\.locale, Locale(identifier: "ja_JP"))
                .task {
                    let email = "harumi.hobby@gmail.com"
                    let password = "A7kL9mQ2R8sT"
                    
                    do {
                        let authClient = AuthClient(client: apiClient)
                        let stockClient = StockClient(client: apiClient)
                        
                        let refreshToken = try await authClient.fetchRefreshToken(mail: email, password: password)
                        let idToken = try await authClient.fetchIdToken(refreshToken: refreshToken)
                        
                        let stockList = try await stockClient.fetchListedInfo(idToken: idToken)
                        print(stockList.count)
                    } catch {
                        print("エラーは無視")
                    }
                }
        }
    }
}
