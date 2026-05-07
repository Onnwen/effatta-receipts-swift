//
//  ErrorContext.swift
//  effatta-receipts-swift
//

import Foundation
import OpenAPIRuntime

func collectBodyForDebug(_ body: HTTPBody?, maxBytes: Int = 8 * 1024) async -> String? {
    guard let body else { return nil }
    do {
        return try await String(collecting: body, upTo: maxBytes)
    } catch {
        return "<failed reading body (cap \(maxBytes) bytes): \(error)>"
    }
}

func formatBody(_ string: String?) -> String {
    guard let string, !string.isEmpty else { return "<no body>" }
    return string
}
