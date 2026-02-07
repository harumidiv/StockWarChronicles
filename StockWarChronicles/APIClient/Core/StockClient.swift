//
//  StockClient.swift
//  StockWarChronicles
//
//  Created by Harumi Sagawa on 2026/02/07.
//

import Foundation

final class StockClient {
    private let client: APIClient

    init(client: APIClient = APIClient()) {
        self.client = client
    }
    
    /// 東証銘柄リスト
    /// - Parameter idToken: idToken
    /// - Returns: 銘柄情報のリスト
    func fetchListedInfo(idToken: String) async throws -> [ListedInfo] {
        let request = ListedInfoRequest(idToken: idToken)
        let response = try await client.send(request)
        return response.info
    }

}
