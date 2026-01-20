//
//  APIClient.swift
//  ResendSwift
//
//  Created by Onnwen Cassitto on 06/07/25.
//

import Foundation
import HTTPTypes
import OpenAPIRuntime
import OpenAPIURLSession

func getConfigureClient(url: URL, credentials: EffattaReceiptsCredentials) throws -> APIProtocol {
    Client(
        serverURL: url,
        transport: URLSessionTransport(),
        middlewares: [
            AuthenticationMiddleware(url: url, credentials: credentials)
        ]
    )
}

package actor AuthenticationMiddleware {
    private let credentials: EffattaReceiptsCredentials

    private let client: APIProtocol
    private var authentication: EffattaReceiptsAuthentication?

    package init(url: URL, credentials: EffattaReceiptsCredentials) {
        self.credentials = credentials
        self.client = Client(
            serverURL: url,
            transport: URLSessionTransport()
        )
    }
    
    private struct EffattaReceiptsAuthentication {
        var token: String
        var expiresAt: Date
    }
}

extension AuthenticationMiddleware: ClientMiddleware {
    package func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        try await checkAuthentication()
        
        guard let token = authentication?.token else {
            throw EffattaReceiptsAuthenticationError.tokenMissing
        }
        
        var request = request
        request.headerFields[.authorization] = "Bearer \(token)"
        return try await next(request, body, baseURL)
    }
    
    private func checkAuthentication() async throws {
        guard authentication == nil || authentication!.expiresAt < Date() else {
            return
        }
        
        let response = try await client.post_sol_api_sol_v1_sol_ade_sol_login(
            .init(
                body: .json(
                    .init(
                        fiscalCode: credentials.fiscalCode,
                        password: credentials.password,
                        pin: credentials.pin,
                        vat: credentials.vat,
                    )
                )
            )
        )
        
        guard case let .ok(response) = response,
              let token = try response.body.json.token
        else {
            throw EffattaReceiptsAuthenticationError.tokenRefreshFailed
        }
        
        authentication = .init(
            token: token,
            expiresAt: Date().addingTimeInterval(60 * 55)
        )
    }
    
    enum EffattaReceiptsAuthenticationError: Error {
        case tokenRefreshFailed
        case tokenMissing
    }
}

public struct EffattaReceiptsCredentials: Sendable {
    let fiscalCode: String
    let password: String
    let vat: String
    let pin: String?
    
    public init(fiscalCode: String, password: String, vat: String, pin: String?) {
        self.fiscalCode = fiscalCode
        self.password = password
        self.vat = vat
        self.pin = pin
    }
}
