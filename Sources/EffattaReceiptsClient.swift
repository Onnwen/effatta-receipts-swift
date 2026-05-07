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
        let operation = "createReceipt"
        let response = try await client.post_sol_api_sol_v1_sol_ade_sol_docs(
            .init(
                body: .json(
                    document,
                ),
            ),
        )

        switch response {
        case .ok(let response):
            do {
                return try response.body.json
            } catch {
                throw EffattaReceiptsError.decodingFailed(operation: operation, underlying: error)
            }
        case .unauthorized:
            throw EffattaReceiptsError.unauthorized(operation: operation)
        case .undocumented(let statusCode, let payload):
            let body = await collectBodyForDebug(payload.body)
            throw EffattaReceiptsError.undocumentedResponse(operation: operation, statusCode: statusCode, body: body)
        }
    }

    public func cancelReceipt(id: String, type: Operations.post_sol_api_sol_v1_sol_ade_sol_docs_sol__lcub_docId_rcub__sol_cancel.Input.Body.jsonPayload._typePayload) async throws {
        let operation = "cancelReceipt"
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

        switch response {
        case .ok, .noContent:
            return
        case .unauthorized:
            throw EffattaReceiptsError.unauthorized(operation: operation)
        case .undocumented(let statusCode, let payload):
            let body = await collectBodyForDebug(payload.body)
            throw EffattaReceiptsError.undocumentedResponse(operation: operation, statusCode: statusCode, body: body)
        }
    }

    public func downloadReceipt(id: String) async throws -> HTTPBody {
        let operation = "downloadReceipt"
        let response = try await client.get_sol_api_sol_v1_sol_ade_sol_docs_sol__lcub_docId_rcub__sol_download(
            .init(
                path: .init(
                    docId: id,
                ),
            ),
        )

        switch response {
        case .ok(let ok):
            do {
                return try ok.body.pdf
            } catch {
                throw EffattaReceiptsError.failedReadingPDF(operation: operation, underlying: error)
            }
        case .unauthorized:
            throw EffattaReceiptsError.unauthorized(operation: operation)
        case .undocumented(let statusCode, let payload):
            let body = await collectBodyForDebug(payload.body)
            throw EffattaReceiptsError.undocumentedResponse(operation: operation, statusCode: statusCode, body: body)
        }
    }

    public enum EffattaReceiptsError: Error, CustomStringConvertible {
        case invalidEnvironmentURL
        case unauthorized(operation: String)
        case undocumentedResponse(operation: String, statusCode: Int, body: String?)
        case decodingFailed(operation: String, underlying: Error)
        case failedReadingPDF(operation: String, underlying: Error)

        public var description: String {
            switch self {
            case .invalidEnvironmentURL:
                return "EffattaReceiptsError.invalidEnvironmentURL"
            case .unauthorized(let operation):
                return "EffattaReceiptsError.unauthorized(operation: \"\(operation)\")"
            case .undocumentedResponse(let operation, let statusCode, let body):
                return """
                EffattaReceiptsError.undocumentedResponse(operation: "\(operation)", statusCode: \(statusCode))
                body: \(formatBody(body))
                """
            case .decodingFailed(let operation, let underlying):
                return """
                EffattaReceiptsError.decodingFailed(operation: "\(operation)")
                underlying: \(underlying)
                """
            case .failedReadingPDF(let operation, let underlying):
                return """
                EffattaReceiptsError.failedReadingPDF(operation: "\(operation)")
                underlying: \(underlying)
                """
            }
        }
    }
}

public enum EffattaReceiptsEnvironment: String {
    case sandbox = "https://sandboxscontrino.effatta.it"
    case production = "https://scontrino.effatta.it"
}
