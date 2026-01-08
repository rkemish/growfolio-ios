//
//  DocumentRepositoryProtocol.swift
//  Growfolio
//
//  Repository protocol for document operations.
//

import Foundation

/// Protocol for document repository operations
protocol DocumentRepositoryProtocol: Sendable {
    /// Fetch documents with optional filtering
    func fetchDocuments(
        type: DocumentType?,
        startDate: Date?,
        endDate: Date?
    ) async throws -> [Document]

    /// Download a document
    func downloadDocument(id: String) async throws -> Data

    /// Fetch W-8BEN tax form
    func fetchW8BENForm() async throws -> Document
}
