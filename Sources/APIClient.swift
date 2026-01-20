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

func getConfigureClient(url: URL) throws -> APIProtocol {
    Client(
        serverURL: url,
        transport: URLSessionTransport(),
        middlewares: []
    )
}
