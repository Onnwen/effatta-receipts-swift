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

    public init(credentials: EffattaReceiptsCredentials, environment: EffattaReceiptsEnvironment) throws {
        guard let url = URL(string: environment.rawValue) else {
            throw EffattaReceiptsError.invalidEnvironmentURL
        }
        
        self.credentials = credentials
        client = try getConfigureClient(url: url, credentials: credentials)
    }
    
    public func createReceipt(_ document: Operations.post_sol_api_sol_v1_sol_ade_sol_docs.Input.Body.jsonPayload) async throws -> Operations.post_sol_api_sol_v1_sol_ade_sol_docs.Output.Ok.Body.jsonPayload {
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

    public enum EffattaReceiptsError: Error {
        case unknown
        case status(Int)
        case invalidEnvironmentURL
        case badStatusCode
    }
}

public enum EffattaReceiptsEnvironment: String {
    case sandbox = "https://sandboxscontrino.effatta.it"
    case production = "https://scontrino.effatta.it"
}
