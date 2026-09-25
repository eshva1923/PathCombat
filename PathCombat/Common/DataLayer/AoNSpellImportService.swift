import Foundation
import SwiftData

enum AoNImportError: LocalizedError {
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Archive of Nethys returned an unexpected response."
        }
    }
}

/// Imports the Pathfinder 2e spell list from Archive of Nethys's public search index.
/// The site's search UI is backed by a public Elasticsearch instance at
/// elasticsearch.aonprd.com — no scraping of rendered pages needed.
enum AoNSpellImportService {
    private static let endpoint = URL(string: "https://elasticsearch.aonprd.com/aon/_search")!

    /// Exact-match action-cost strings that map onto our discrete speed encoding.
    /// Anything else (durations like "10 minutes", variable costs like "Single Action
    /// to Three Actions") becomes speed 4 (Special), with the raw text preserved in details.
    private static let actionSpeedMap: [String: Int] = [
        "Reaction": -1,
        "Free Action": 0,
        "Single Action": 1,
        "Two Actions": 2,
        "Three Actions": 3
    ]

    private static let requestBody: [String: Any] = [
        "from": 0,
        "size": 10000,
        "_source": ["name", "level", "spell_type", "tradition", "actions", "range_raw", "area_raw", "trait_raw", "url", "markdown"],
        "query": [
            "bool": [
                "must": [["match": ["category": "spell"]]],
                "must_not": [
                    ["exists": ["field": "remaster_id"]],
                    ["term": ["exclude_from_search": true]]
                ]
            ]
        ]
    ]

    private struct SearchResponse: Decodable {
        struct HitsWrapper: Decodable {
            struct Hit: Decodable {
                let _source: SpellSource
            }
            let hits: [Hit]
        }
        let hits: HitsWrapper
    }

    private struct SpellSource: Decodable {
        let name: String
        let level: Int?
        let spell_type: String?
        let tradition: [String]?
        let actions: String?
        let range_raw: String?
        let area_raw: String?
        let trait_raw: [String]?
        let url: String?
        let markdown: String?
    }

    /// Fetches the current spell list and upserts it into the store, matching existing
    /// spells by `aonID`. Spells already imported get every field refreshed from AoN;
    /// spells you created yourself (no matching `aonID`) are never touched. Returns the
    /// number of spells processed.
    static func importSpells(context: ModelContext) async throws -> Int {
        let sources = try await fetchSpellSources()

        let existing = try context.fetch(FetchDescriptor<Spell>())
        var existingByAonID: [Int: Spell] = [:]
        for spell in existing {
            if let aonID = spell.aonID {
                existingByAonID[aonID] = spell
            }
        }

        var count = 0
        for source in sources {
            guard let mapped = makeSpell(from: source), let aonID = mapped.aonID else { continue }
            if let match = existingByAonID[aonID] {
                match.name = mapped.name
                match.level = mapped.level
                match.isFocusSpell = mapped.isFocusSpell
                match.details = mapped.details
                match.traditions = mapped.traditions
                match.speed = mapped.speed
                match.range = mapped.range
                match.area = mapped.area
                match.tags = mapped.tags
            } else {
                context.insert(mapped)
            }
            count += 1
        }

        try context.save()
        return count
    }

    private static func fetchSpellSources() async throws -> [SpellSource] {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AoNImportError.invalidResponse
        }
        let decoded = try JSONDecoder().decode(SearchResponse.self, from: data)
        return decoded.hits.hits.map { $0._source }
    }

    private static func makeSpell(from source: SpellSource) -> Spell? {
        guard let aonID = aonID(from: source.url) else { return nil }

        let isFocusSpell = source.spell_type == "Focus"
        let isCantrip = source.spell_type == "Cantrip"
        let level = isCantrip ? 0 : (source.level ?? 1)
        let traditions = (source.tradition ?? []).compactMap { SpellTradition(rawValue: $0) }
        let tags = source.trait_raw ?? []

        var details = extractDetails(from: source.markdown ?? "")
        let speed: Int
        if let raw = source.actions, let mapped = actionSpeedMap[raw] {
            speed = mapped
        } else {
            speed = 4
            details += "\n\n* Special casting time: \(source.actions ?? "Unknown")"
        }

        return Spell(
            name: source.name,
            id: nil,
            level: level,
            isFocusSpell: isFocusSpell,
            details: details,
            aonID: aonID,
            traditions: traditions,
            speed: speed,
            range: stripAonMarkup(source.range_raw ?? ""),
            area: stripAonMarkup(source.area_raw ?? ""),
            tags: tags)
    }

    private static func aonID(from urlString: String?) -> Int? {
        guard let urlString,
              let range = urlString.range(of: #"ID=(\d+)"#, options: .regularExpression) else { return nil }
        return Int(urlString[range].dropFirst(3))
    }

    /// Everything after the header block, which may itself contain further `---`-separated
    /// segments (e.g. a trailing "Heightened" scaling note) — only the first `---` (which
    /// divides the structured header from the narrative body) should be dropped, not every
    /// occurrence, or later segments get discarded along with the main description.
    private static func extractDetails(from markdown: String) -> String {
        let parts = markdown.components(separatedBy: "\n---\n")
        var body = parts.count > 1 ? parts.dropFirst().joined(separator: "\n\n") : markdown
        body = stripAonMarkup(body)
        body = body.replacingOccurrences(of: #"<br\s*/?>"#, with: "\n", options: .regularExpression)
        body = body.replacingOccurrences(of: #"</li>"#, with: "\n", options: .regularExpression)
        body = body.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
        return body.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Strips AoN's link markup, keeping only the visible text: `{{rules 2387 "emanation"}}`
    /// becomes `emanation`, and Markdown-style `[text](url)` links become `text`.
    private static func stripAonMarkup(_ text: String) -> String {
        var result = text
        result = result.replacingOccurrences(of: #"\{\{[^{}]*?"([^"]*)"[^{}]*?\}\}"#, with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\{\{[^{}]*?\}\}"#, with: "", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\[([^\]]*)\]\([^)]*\)"#, with: "$1", options: .regularExpression)
        return result
    }
}
