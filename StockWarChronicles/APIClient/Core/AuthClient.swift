//
//  AuthClient.swift
//  StockWarChronicles
//
//  Created by Harumi Sagawa on 2026/02/07.
//

import Foundation

// MARK: - AuthClient (認証関連のAPIを扱う)
    
final class AuthClient {
    private let client: APIClient

    init(client: APIClient = APIClient()) {
        self.client = client
    }
    
    func fetchRefreshToken(mail: String, password: String) async throws -> String {
        let request = RefreshTokenRequest(mail: mail, password: password)
        let response = try await client.send(request)
        return response.refreshToken
    }
    
    func fetchIdToken(refreshToken: String) async throws -> String {
        let request = IdTokenRequest(refreshToken: refreshToken)
        let response = try await client.send(request)
        return response.idToken
    }
}
