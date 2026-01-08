//
//  DocumentRepository.swift
//  Growfolio
//
//  Repository implementation for document operations using APIClient.
//

import Foundation

/// Repository for document operations
final class DocumentRepository: DocumentRepositoryProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func fetchDocuments(
        type: DocumentType? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) async throws -> [Document] {
        try await apiClient.request(
            Endpoints.GetDocuments(
                type: type,
                startDate: startDate,
                endDate: endDate
            )
        )
    }

    func downloadDocument(id: String) async throws -> Data {
        try await apiClient.request(Endpoints.DownloadDocument(documentId: id))
    }

    func fetchW8BENForm() async throws -> Document {
        try await apiClient.request(Endpoints.GetW8BENForm())
    }
}
