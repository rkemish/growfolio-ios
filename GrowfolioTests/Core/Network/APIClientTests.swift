//
//  APIClientTests.swift
//  GrowfolioTests
//
//  Tests for APIClient, PaginatedResponse, and APIResponse.
//

import XCTest
@testable import Growfolio

final class APIClientTests: XCTestCase {

    // MARK: - PaginatedResponse Tests

    func testPaginatedResponseDecoding() throws {
        let json = """
        {
            "data": [
                {"id": "1", "name": "Item 1"},
                {"id": "2", "name": "Item 2"}
            ],
            "pagination": {
                "page": 1,
                "limit": 10,
                "total_pages": 5,
                "total_items": 50
            }
        }
        """.data(using: .utf8)!

        struct TestItem: Codable, Sendable {
            let id: String
            let name: String
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(PaginatedResponse<TestItem>.self, from: json)

        XCTAssertEqual(response.data.count, 2)
        XCTAssertEqual(response.data[0].id, "1")
        XCTAssertEqual(response.data[0].name, "Item 1")
        XCTAssertEqual(response.pagination.page, 1)
        XCTAssertEqual(response.pagination.limit, 10)
        XCTAssertEqual(response.pagination.totalPages, 5)
        XCTAssertEqual(response.pagination.totalItems, 50)
    }

    func testPaginatedResponseHasNextPage() throws {
        let json = """
        {
            "data": [],
            "pagination": {
                "page": 2,
                "limit": 10,
                "total_pages": 5,
                "total_items": 50
            }
        }
        """.data(using: .utf8)!

        struct EmptyItem: Codable, Sendable {}

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(PaginatedResponse<EmptyItem>.self, from: json)

        XCTAssertTrue(response.pagination.hasNextPage)
    }

    func testPaginatedResponseNoNextPageOnLastPage() throws {
        let json = """
        {
            "data": [],
            "pagination": {
                "page": 5,
                "limit": 10,
                "total_pages": 5,
                "total_items": 50
            }
        }
        """.data(using: .utf8)!

        struct EmptyItem: Codable, Sendable {}

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(PaginatedResponse<EmptyItem>.self, from: json)

        XCTAssertFalse(response.pagination.hasNextPage)
    }

    func testPaginatedResponseHasPreviousPage() throws {
        let json = """
        {
            "data": [],
            "pagination": {
                "page": 3,
                "limit": 10,
                "total_pages": 5,
                "total_items": 50
            }
        }
        """.data(using: .utf8)!

        struct EmptyItem: Codable, Sendable {}

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(PaginatedResponse<EmptyItem>.self, from: json)

        XCTAssertTrue(response.pagination.hasPreviousPage)
    }

    func testPaginatedResponseNoPreviousPageOnFirstPage() throws {
        let json = """
        {
            "data": [],
            "pagination": {
                "page": 1,
                "limit": 10,
                "total_pages": 5,
                "total_items": 50
            }
        }
        """.data(using: .utf8)!

        struct EmptyItem: Codable, Sendable {}

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(PaginatedResponse<EmptyItem>.self, from: json)

        XCTAssertFalse(response.pagination.hasPreviousPage)
    }

    func testPaginatedResponseWithEmptyData() throws {
        let json = """
        {
            "data": [],
            "pagination": {
                "page": 1,
                "limit": 10,
                "total_pages": 0,
                "total_items": 0
            }
        }
        """.data(using: .utf8)!

        struct EmptyItem: Codable, Sendable {}

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(PaginatedResponse<EmptyItem>.self, from: json)

        XCTAssertTrue(response.data.isEmpty)
        XCTAssertEqual(response.pagination.totalItems, 0)
    }

    func testPaginatedResponseEncoding() throws {
        struct TestItem: Codable, Sendable {
            let id: String
        }

        let pagination = PaginatedResponse<TestItem>.Pagination(
            page: 1,
            limit: 10,
            totalPages: 2,
            totalItems: 15
        )
        let response = PaginatedResponse(
            data: [TestItem(id: "1")],
            pagination: pagination
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        let paginationJson = json["pagination"] as! [String: Any]
        XCTAssertEqual(paginationJson["page"] as? Int, 1)
        XCTAssertEqual(paginationJson["total_pages"] as? Int, 2)
    }

    // MARK: - APIResponse Tests

    func testAPIResponseDecoding() throws {
        let json = """
        {
            "data": {
                "id": "123",
                "value": "test"
            },
            "meta": {
                "request_id": "abc123",
                "timestamp": "2024-01-15T10:30:00Z"
            }
        }
        """.data(using: .utf8)!

        struct TestData: Codable, Sendable {
            let id: String
            let value: String
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(APIResponse<TestData>.self, from: json)

        XCTAssertEqual(response.data.id, "123")
        XCTAssertEqual(response.data.value, "test")
        XCTAssertEqual(response.meta?["request_id"], "abc123")
    }

    func testAPIResponseDecodingWithNullMeta() throws {
        let json = """
        {
            "data": {
                "id": "456"
            },
            "meta": null
        }
        """.data(using: .utf8)!

        struct TestData: Codable, Sendable {
            let id: String
        }

        let decoder = JSONDecoder()
        let response = try decoder.decode(APIResponse<TestData>.self, from: json)

        XCTAssertEqual(response.data.id, "456")
        XCTAssertNil(response.meta)
    }

    func testAPIResponseDecodingWithMissingMeta() throws {
        let json = """
        {
            "data": {
                "id": "789"
            }
        }
        """.data(using: .utf8)!

        struct TestData: Codable, Sendable {
            let id: String
        }

        let decoder = JSONDecoder()
        let response = try decoder.decode(APIResponse<TestData>.self, from: json)

        XCTAssertEqual(response.data.id, "789")
        XCTAssertNil(response.meta)
    }

    func testAPIResponseEncoding() throws {
        struct TestData: Codable, Sendable {
            let id: String
        }

        let response = APIResponse(
            data: TestData(id: "test-id"),
            meta: ["key": "value"]
        )

        let data = try JSONEncoder().encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        let dataJson = json["data"] as! [String: Any]
        XCTAssertEqual(dataJson["id"] as? String, "test-id")

        let metaJson = json["meta"] as! [String: String]
        XCTAssertEqual(metaJson["key"], "value")
    }

    // MARK: - APIClientProtocol Tests

    func testAPIClientProtocolConformance() {
        // Verify APIClient conforms to APIClientProtocol
        let client: any APIClientProtocol = APIClient.shared
        XCTAssertNotNil(client)
    }

    // MARK: - HTTP Method Tests

    func testHTTPMethodRawValues() {
        XCTAssertEqual(HTTPMethod.get.rawValue, "GET")
        XCTAssertEqual(HTTPMethod.post.rawValue, "POST")
        XCTAssertEqual(HTTPMethod.put.rawValue, "PUT")
        XCTAssertEqual(HTTPMethod.patch.rawValue, "PATCH")
        XCTAssertEqual(HTTPMethod.delete.rawValue, "DELETE")
    }

    // MARK: - Endpoint Protocol Tests

    func testEndpointDefaultValues() {
        struct TestEndpoint: Endpoint {
            var path: String { "/test" }
            var method: HTTPMethod { .get }
        }

        let endpoint = TestEndpoint()

        XCTAssertNil(endpoint.queryItems)
        XCTAssertNil(endpoint.headers)
        XCTAssertNil(endpoint.body)
        XCTAssertTrue(endpoint.requiresAuthentication)
        XCTAssertEqual(endpoint.timeout, Constants.API.requestTimeout)
    }

    func testEndpointCustomValues() {
        struct CustomEndpoint: Endpoint {
            var path: String { "/custom" }
            var method: HTTPMethod { .post }
            var queryItems: [URLQueryItem]? { [URLQueryItem(name: "key", value: "value")] }
            var headers: [String: String]? { ["X-Custom": "header"] }
            var body: Data? { "body".data(using: .utf8) }
            var requiresAuthentication: Bool { false }
            var timeout: TimeInterval { 120 }
        }

        let endpoint = CustomEndpoint()

        XCTAssertEqual(endpoint.path, "/custom")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertEqual(endpoint.queryItems?.count, 1)
        XCTAssertEqual(endpoint.queryItems?.first?.name, "key")
        XCTAssertEqual(endpoint.headers?["X-Custom"], "header")
        XCTAssertNotNil(endpoint.body)
        XCTAssertFalse(endpoint.requiresAuthentication)
        XCTAssertEqual(endpoint.timeout, 120)
    }

    // MARK: - PaginatedResponse Pagination Edge Cases

    func testPaginationSinglePage() {
        let pagination = PaginatedResponse<String>.Pagination(
            page: 1,
            limit: 10,
            totalPages: 1,
            totalItems: 5
        )

        XCTAssertFalse(pagination.hasNextPage)
        XCTAssertFalse(pagination.hasPreviousPage)
    }

    func testPaginationMiddlePage() {
        let pagination = PaginatedResponse<String>.Pagination(
            page: 3,
            limit: 10,
            totalPages: 5,
            totalItems: 45
        )

        XCTAssertTrue(pagination.hasNextPage)
        XCTAssertTrue(pagination.hasPreviousPage)
    }

    func testPaginationFirstPage() {
        let pagination = PaginatedResponse<String>.Pagination(
            page: 1,
            limit: 10,
            totalPages: 5,
            totalItems: 45
        )

        XCTAssertTrue(pagination.hasNextPage)
        XCTAssertFalse(pagination.hasPreviousPage)
    }

    func testPaginationLastPage() {
        let pagination = PaginatedResponse<String>.Pagination(
            page: 5,
            limit: 10,
            totalPages: 5,
            totalItems: 45
        )

        XCTAssertFalse(pagination.hasNextPage)
        XCTAssertTrue(pagination.hasPreviousPage)
    }

    func testPaginationZeroPages() {
        let pagination = PaginatedResponse<String>.Pagination(
            page: 1,
            limit: 10,
            totalPages: 0,
            totalItems: 0
        )

        XCTAssertFalse(pagination.hasNextPage)
        XCTAssertFalse(pagination.hasPreviousPage)
    }

    // MARK: - Complex Data Types

    func testPaginatedResponseWithComplexType() throws {
        let json = """
        {
            "data": [
                {
                    "id": "p1",
                    "name": "Portfolio 1",
                    "total_value": 10000.50,
                    "holdings": [
                        {"symbol": "AAPL", "quantity": 10}
                    ]
                }
            ],
            "pagination": {
                "page": 1,
                "limit": 20,
                "total_pages": 1,
                "total_items": 1
            }
        }
        """.data(using: .utf8)!

        struct Holding: Codable, Sendable {
            let symbol: String
            let quantity: Int
        }

        struct Portfolio: Codable, Sendable {
            let id: String
            let name: String
            let totalValue: Double
            let holdings: [Holding]
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(PaginatedResponse<Portfolio>.self, from: json)

        XCTAssertEqual(response.data.count, 1)
        XCTAssertEqual(response.data[0].id, "p1")
        XCTAssertEqual(response.data[0].totalValue, 10000.50)
        XCTAssertEqual(response.data[0].holdings.count, 1)
        XCTAssertEqual(response.data[0].holdings[0].symbol, "AAPL")
    }

    func testAPIResponseWithNestedData() throws {
        let json = """
        {
            "data": {
                "user": {
                    "id": "u1",
                    "profile": {
                        "name": "Test User",
                        "email": "test@example.com"
                    }
                }
            },
            "meta": null
        }
        """.data(using: .utf8)!

        struct Profile: Codable, Sendable {
            let name: String
            let email: String
        }

        struct User: Codable, Sendable {
            let id: String
            let profile: Profile
        }

        struct ResponseData: Codable, Sendable {
            let user: User
        }

        let response = try JSONDecoder().decode(APIResponse<ResponseData>.self, from: json)

        XCTAssertEqual(response.data.user.id, "u1")
        XCTAssertEqual(response.data.user.profile.name, "Test User")
        XCTAssertEqual(response.data.user.profile.email, "test@example.com")
    }

    // MARK: - Sendable Conformance Tests

    func testPaginatedResponseIsSendable() {
        let pagination = PaginatedResponse<String>.Pagination(
            page: 1,
            limit: 10,
            totalPages: 1,
            totalItems: 5
        )
        let response = PaginatedResponse(
            data: ["item1", "item2"],
            pagination: pagination
        )

        Task {
            let copy = response
            XCTAssertEqual(copy.data.count, 2)
        }
    }

    func testAPIResponseIsSendable() {
        let response = APIResponse(
            data: "test-data",
            meta: nil
        )

        Task {
            let copy = response
            XCTAssertEqual(copy.data, "test-data")
        }
    }

    // MARK: - Large Dataset Tests

    func testPaginatedResponseLargePage() throws {
        var items: [[String: String]] = []
        for i in 0..<1000 {
            items.append(["id": "\(i)"])
        }

        let jsonObject: [String: Any] = [
            "data": items,
            "pagination": [
                "page": 1,
                "limit": 1000,
                "total_pages": 100,
                "total_items": 100000
            ]
        ]

        let data = try JSONSerialization.data(withJSONObject: jsonObject)

        struct Item: Codable, Sendable {
            let id: String
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(PaginatedResponse<Item>.self, from: data)

        XCTAssertEqual(response.data.count, 1000)
        XCTAssertEqual(response.pagination.totalItems, 100000)
        XCTAssertTrue(response.pagination.hasNextPage)
    }

    // MARK: - APIClient Shared Instance

    func testAPIClientSharedInstance() {
        let instance1 = APIClient.shared
        let instance2 = APIClient.shared

        // Both should reference the same actor instance
        XCTAssertNotNil(instance1)
        XCTAssertNotNil(instance2)
    }

    // MARK: - Decoding Error Handling

    func testPaginatedResponseInvalidJSON() {
        let invalidJSON = "not valid json".data(using: .utf8)!

        struct Item: Codable, Sendable {
            let id: String
        }

        XCTAssertThrowsError(try JSONDecoder().decode(PaginatedResponse<Item>.self, from: invalidJSON))
    }

    func testPaginatedResponseMissingPagination() {
        let json = """
        {
            "data": [{"id": "1"}]
        }
        """.data(using: .utf8)!

        struct Item: Codable, Sendable {
            let id: String
        }

        XCTAssertThrowsError(try JSONDecoder().decode(PaginatedResponse<Item>.self, from: json))
    }

    func testAPIResponseMissingData() {
        let json = """
        {
            "meta": {}
        }
        """.data(using: .utf8)!

        struct Item: Codable, Sendable {
            let id: String
        }

        XCTAssertThrowsError(try JSONDecoder().decode(APIResponse<Item>.self, from: json))
    }

    // MARK: - Special Characters

    func testPaginatedResponseWithSpecialCharacters() throws {
        let json = """
        {
            "data": [
                {"id": "1", "name": "Item with 'quotes' and \\"escapes\\""},
                {"id": "2", "name": "Unicode: 日本語 한국어 🎉"}
            ],
            "pagination": {
                "page": 1,
                "limit": 10,
                "total_pages": 1,
                "total_items": 2
            }
        }
        """.data(using: .utf8)!

        struct Item: Codable, Sendable {
            let id: String
            let name: String
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(PaginatedResponse<Item>.self, from: json)

        XCTAssertEqual(response.data.count, 2)
        XCTAssertTrue(response.data[1].name.contains("日本語"))
    }

    // MARK: - Number Types

    func testPaginatedResponseWithLargeTotalItems() throws {
        let json = """
        {
            "data": [],
            "pagination": {
                "page": 1,
                "limit": 100,
                "total_pages": 21474836,
                "total_items": 2147483647
            }
        }
        """.data(using: .utf8)!

        struct EmptyItem: Codable, Sendable {}

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(PaginatedResponse<EmptyItem>.self, from: json)

        XCTAssertEqual(response.pagination.totalItems, 2147483647)
    }

    // MARK: - APIResponse Meta Edge Cases

    func testAPIResponseWithEmptyMeta() throws {
        let json = """
        {
            "data": {"id": "1"},
            "meta": {}
        }
        """.data(using: .utf8)!

        struct Item: Codable, Sendable {
            let id: String
        }

        let response = try JSONDecoder().decode(APIResponse<Item>.self, from: json)

        XCTAssertNotNil(response.meta)
        XCTAssertTrue(response.meta?.isEmpty ?? false)
    }

    func testAPIResponseWithManyMetaEntries() throws {
        var metaDict: [String: String] = [:]
        for i in 0..<100 {
            metaDict["key_\(i)"] = "value_\(i)"
        }

        let jsonObject: [String: Any] = [
            "data": ["id": "1"],
            "meta": metaDict
        ]

        let data = try JSONSerialization.data(withJSONObject: jsonObject)

        struct Item: Codable, Sendable {
            let id: String
        }

        let response = try JSONDecoder().decode(APIResponse<Item>.self, from: data)

        XCTAssertEqual(response.meta?.count, 100)
        XCTAssertEqual(response.meta?["key_50"], "value_50")
    }
}
