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

/// The three AoN fields that link a document to its remaster/legacy counterpart. A
/// pre-remaster document carries `remaster_id` pointing forward to its replacement; the
/// current document carries `legacy_id` pointing back to what it replaced.
protocol AoNVersionedSource: Decodable {
    var id: String { get }
    var legacy_id: [String]? { get }
    var remaster_id: [String]? { get }
}

/// Shared plumbing for querying Archive of Nethys's public Elasticsearch search index
/// (elasticsearch.aonprd.com) — no scraping of rendered pages needed.
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

    /// Fetches every document of the given AoN `category` (e.g. "spell", "condition"),
    /// excluding only AoN's own hidden/errata entries. Includes both current and
    /// pre-remaster documents — callers needing just the current ones should pass the
    /// result through `resolveKeepersWithLegacy`.
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

    /// Parses the trailing `ID=123` numeric id out of an AoN page URL (e.g. `/Spells.aspx?ID=119`).
    static func aonID(from urlString: String?) -> Int? {
        guard let urlString,
              let range = urlString.range(of: #"ID=(\d+)"#, options: .regularExpression) else { return nil }
        return Int(urlString[range].dropFirst(3))
    }

    /// Splits a fetched category into "keepers" (documents with no `remaster_id`, i.e. either
    /// never remastered or the current remastered version) paired with the legacy document
    /// they supersede, if any — so callers can fold the legacy text into the keeper's record
    /// instead of creating a second one.
    static func resolveKeepersWithLegacy<Source: AoNVersionedSource>(_ all: [Source]) -> [(keeper: Source, legacy: Source?)] {
        let byID = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
        let keepers = all.filter { ($0.remaster_id ?? []).isEmpty }
        return keepers.map { keeper in
            let legacy = keeper.legacy_id?.first.flatMap { byID[$0] }
            return (keeper, legacy)
        }
    }
}
