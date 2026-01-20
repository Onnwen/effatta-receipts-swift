//
//  EffattaReceiptsClient.swift
//  effatta-receipts-swift
//
//  Created by Onnwen Cassitto on 20/01/26.
//

import Foundation
import OpenAPIRuntime

public final actor EffattaReceiptsClient {
    private let client: APIProtocol
    
    private let credentials: EffattaReceiptsCredentials
    private var authentication: EffattaReceiptsAuthentication?

    public init(credentials: EffattaReceiptsCredentials, environment: EffattaReceiptsEnvironment) throws {
        guard let url = URL(string: environment.rawValue) else {
            throw EffattaReceiptsError.invalidEnvironmentURL
        }
        
        self.credentials = credentials
        client = try getConfigureClient(url: url)
    }
    
    public func createReceipt(_ document: Operations.post_sol_api_sol_v1_sol_ade_sol_docs.Input.Body.jsonPayload) async throws -> Operations.post_sol_api_sol_v1_sol_ade_sol_docs.Output.Ok.Body.jsonPayload {
        try await checkAuthentication()
        
        let response = try await client.post_sol_api_sol_v1_sol_ade_sol_docs(
            .init(
                body: .json(
                    document
                )
            )
        )
        
        guard case let .ok(response) = response else {
            throw EffattaReceiptsError.badStatusCode
        }
        
        return try response.body.json
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
                        vat: credentials.vat
                    )
                )
            )
        )
        
        guard case let .ok(response) = response,
              let token = try response.body.json.token
        else {
            throw EffattaReceiptsError.authenticationFailed
        }
        
        authentication = .init(
            token: token,
            expiresAt: Date().addingTimeInterval(60 * 55)
        )
        
    }
    
    private struct EffattaReceiptsAuthentication {
        var token: String
        var expiresAt: Date
    }

    enum EffattaReceiptsError: Error {
        case unknown
        case status(Int)
        case invalidEnvironmentURL
        case authenticationFailed
        case badStatusCode
    }
}

public enum EffattaReceiptsEnvironment: String {
    case sandbox = "https://sandboxscontrino.effatta.it"
    case production = "https://scontrino.effatta.it"
}

public struct EffattaReceiptsCredentials: Sendable {
    let fiscalCode: String
    let password: String
    let vat: String
    
    public init(fiscalCode: String, password: String, vat: String) {
        self.fiscalCode = fiscalCode
        self.password = password
        self.vat = vat
    }
}
