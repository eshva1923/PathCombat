import Foundation

enum AoNImportError: LocalizedError {
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Archive of Nethys returned an unexpected response."
        }
    }
}

protocol AoNVersionedSource: Decodable {
    var legacy_id: [String]? { get }
    var remaster_id: [String]? { get }
    var release_date: String? { get }
}

struct AoNImportResult {
    let imported: Int
    let skipped: Int
}

enum AoNSearchClient {
    private static let endpoint = URL(string: "https://elasticsearch.aonprd.com/aon/_search")!

    private struct SearchResponse<Source: Decodable>: Decodable {
        struct HitsWrapper: Decodable {
            struct Hit: Decodable {
                let _source: Source
            }
            let hits: [Hit]
        }
        let hits: HitsWrapper
    }

    static func fetchAll<Source: Decodable>(category: String, sourceFields: [String]) async throws -> [Source] {
        let requestBody: [String: Any] = [
            "from": 0,
            "size": 10000,
            "_source": sourceFields,
            "query": [
                "bool": [
                    "must": [["match": ["category": category]]],
                    "must_not": [
                        ["term": ["exclude_from_search": true]]
                    ]
                ]
            ]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AoNImportError.invalidResponse
        }
        let decoded = try JSONDecoder().decode(SearchResponse<Source>.self, from: data)
        return decoded.hits.hits.map { $0._source }
    }

    static func aonID(from urlString: String?) -> Int? {
        guard let urlString,
              let range = urlString.range(of: #"ID=(\d+)"#, options: .regularExpression) else { return nil }
        return Int(urlString[range].dropFirst(3))
    }

    static func resolveKeepers<Source: AoNVersionedSource>(_ all: [Source]) -> [Source] {
        all.filter { ($0.remaster_id ?? []).isEmpty }
    }

    private static let orcCutoffDate = "2023-11-15"

    static func isORC<Source: AoNVersionedSource>(_ keeper: Source) -> Bool {
        if let legacyID = keeper.legacy_id, !legacyID.isEmpty { return true }
        guard let releaseDate = keeper.release_date else { return true }
        return releaseDate >= orcCutoffDate
    }
}
