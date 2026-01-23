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
                    document,
                ),
            ),
        )

        dump(response)

        guard case let .ok(response) = response else {
            throw EffattaReceiptsError.badStatusCode
        }

        do {
            return try response.body.json
        } catch {
            dump(response)
            dump(error)
            dump(error.localizedDescription)
            throw EffattaReceiptsError.unknown
        }
    }

    public func cancelReceipt(id: String, type: Operations.post_sol_api_sol_v1_sol_ade_sol_docs_sol__lcub_docId_rcub__sol_cancel.Input.Body.jsonPayload._typePayload) async throws {
        let response = try await client.post_sol_api_sol_v1_sol_ade_sol_docs_sol__lcub_docId_rcub__sol_cancel(
            .init(
                path: .init(docId: id),
                body: .json(
                    .init(
                        _type: type,
                        items: type == .refund ? [1] : nil,
                    ),
                ),
            ),
        )

        guard response == .ok || response == .noContent else {
            dump(response)
            throw EffattaReceiptsError.badStatusCode
        }
    }

    public func downloadReceipt(id: String) async throws -> HTTPBody {
        let response = try await client.get_sol_api_sol_v1_sol_ade_sol_docs_sol__lcub_docId_rcub__sol_download(
            .init(
                path: .init(
                    docId: id,
                ),
            ),
        )

        guard case let .ok(body) = response else {
            throw EffattaReceiptsError.badStatusCode
        }

        do {
            return try body.body.pdf
        } catch {
            dump(response)
            dump(error)
            dump(error.localizedDescription)
            throw EffattaReceiptsError.failedReadingPDF(error.localizedDescription)
        }
    }

    public enum EffattaReceiptsError: Error {
        case unknown
        case status(Int)
        case invalidEnvironmentURL
        case badStatusCode
        case failedReadingPDF(String)
    }
}

public enum EffattaReceiptsEnvironment: String {
    case sandbox = "https://sandboxscontrino.effatta.it"
    case production = "https://scontrino.effatta.it"
}
