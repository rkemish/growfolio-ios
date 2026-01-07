//
//  AuthModels.swift
//  Growfolio
//
//  Models for authentication API requests/responses.
//

import Foundation

struct AppleTokenExchangeRequest: Encodable, Sendable {
    let identityToken: String
    let userFirstName: String?
    let userLastName: String?
}

struct AppleTokenExchangeResponse: Decodable, Sendable {
    let userId: String
    let email: String?
    let name: String?
    let alpacaAccountStatus: String?
}

struct TokenResponse: Codable, Sendable, Equatable {
    let accessToken: String
    let refreshToken: String?
    let idToken: String?
    let tokenType: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case idToken = "id_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
}
