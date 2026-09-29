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

/// The AoN fields used to tell a document's remaster/ORC status. A pre-remaster document
/// carries `remaster_id` pointing forward to its replacement; a remastered document carries
/// a non-empty `legacy_id`. `release_date` is the fallback signal for documents with neither.
protocol AoNVersionedSource: Decodable {
    var legacy_id: [String]? { get }
    var remaster_id: [String]? { get }
    var release_date: String? { get }
}

/// The outcome of an ORC-filtered AoN import: how many entries were imported/refreshed, and
/// how many were skipped because they're legacy (pre-remaster OGL) material with no ORC
/// equivalent. Nothing already in the library is ever touched by this filtering.
struct AoNImportResult {
    let imported: Int
    let skipped: Int
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
    /// result through `resolveKeepers`.
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

    /// Filters a fetched category down to "keepers": documents with no `remaster_id`, i.e.
    /// either never remastered or the current remastered version. Excludes pre-remaster
    /// documents that have since been superseded, so they don't show up as duplicates
    /// alongside their replacement.
    static func resolveKeepers<Source: AoNVersionedSource>(_ all: [Source]) -> [Source] {
        all.filter { ($0.remaster_id ?? []).isEmpty }
    }

    /// Player Core and GM Core's release date — Paizo's switch from the OGL to the ORC license.
    private static let orcCutoffDate = "2023-11-15"

    /// Whether a keeper document counts as ORC-licensed material. AoN has no explicit license
    /// field, so this is inferred: a document with a `legacy_id` is itself the remastered
    /// replacement of an older OGL document, so it's always ORC. Otherwise, its own release
    /// date decides. An undated document is assumed to be fine to include.
    static func isORC<Source: AoNVersionedSource>(_ keeper: Source) -> Bool {
        if let legacyID = keeper.legacy_id, !legacyID.isEmpty { return true }
        guard let releaseDate = keeper.release_date else { return true }
        return releaseDate >= orcCutoffDate
    }
}
