//
//  MockDocumentRepository.swift
//  Growfolio
//
//  Mock document repository for previews and testing.
//

import Foundation

/// Mock implementation of document repository
final class MockDocumentRepository: DocumentRepositoryProtocol, @unchecked Sendable {
    private let store = MockDataStore.shared
    var shouldFail = false
    var errorToThrow: Error?

    init(documents: [Document] = []) {
        Task {
            for document in documents {
                await store.addDocument(document)
            }
        }
    }

    func fetchDocuments(
        type: DocumentType? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) async throws -> [Document] {
        if shouldFail {
            throw errorToThrow ?? NetworkError.serverError(statusCode: 500, message: "Mock error")
        }
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay

        var filtered = await store.documents

        if let type = type {
            filtered = filtered.filter { $0.type == type }
        }

        if let startDate = startDate {
            filtered = filtered.filter { $0.createdAt >= startDate }
        }

        if let endDate = endDate {
            filtered = filtered.filter { $0.createdAt <= endDate }
        }

        return filtered
    }

    func downloadDocument(id: String) async throws -> Data {
        if shouldFail {
            throw errorToThrow ?? NetworkError.serverError(statusCode: 500, message: "Mock error")
        }
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s delay

        guard await store.getDocument(id: id) != nil else {
            throw NetworkError.notFound
        }

        // Return mock PDF data
        return "Mock PDF Content".data(using: .utf8) ?? Data()
    }

    func fetchW8BENForm() async throws -> Document {
        if shouldFail {
            throw errorToThrow ?? NetworkError.serverError(statusCode: 500, message: "Mock error")
        }
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay

        return Document(
            id: "w8ben-form",
            userId: "mock-user",
            type: .w8ben,
            title: "W-8BEN Tax Form",
            description: "Certificate of Foreign Status of Beneficial Owner",
            fileUrl: URL(string: "https://example.com/w8ben.pdf")!,
            fileSize: 524288, // 512 KB
            mimeType: "application/pdf",
            createdAt: Date()
        )
    }
}
