import Foundation
import SwiftData

/// Imports the Pathfinder 2e spell list from Archive of Nethys's public search index.
enum AoNSpellImportService {
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

    private static let sourceFields = [
        "name", "level", "spell_type", "tradition", "actions", "range_raw", "area_raw", "trait_raw",
        "url", "markdown", "id", "legacy_id", "remaster_id"
    ]

    private struct SpellSource: AoNVersionedSource {
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
        let id: String
        let legacy_id: [String]?
        let remaster_id: [String]?
    }

    /// Fetches the current spell list and upserts it into the store, matching existing
    /// spells by `aonID`. Spells already imported get every field refreshed from AoN;
    /// spells you created yourself (no matching `aonID`) are never touched. Returns the
    /// number of spells processed.
    static func importSpells(context: ModelContext, includeLegacyDescriptions: Bool = false) async throws -> Int {
        let sources: [SpellSource] = try await AoNSearchClient.fetchAll(category: "spell", sourceFields: sourceFields)
        let pairs = AoNSearchClient.resolveKeepersWithLegacy(sources)

        let existing = try context.fetch(FetchDescriptor<Spell>())
        var existingByAonID: [Int: Spell] = [:]
        for spell in existing {
            if let aonID = spell.aonID {
                existingByAonID[aonID] = spell
            }
        }

        var count = 0
        for (keeper, legacy) in pairs {
            let legacyToMerge = includeLegacyDescriptions ? legacy : nil
            guard let mapped = makeSpell(from: keeper, legacy: legacyToMerge), let aonID = mapped.aonID else { continue }
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

    private static func makeSpell(from keeper: SpellSource, legacy: SpellSource?) -> Spell? {
        guard let aonID = AoNSearchClient.aonID(from: keeper.url) else { return nil }

        let isFocusSpell = keeper.spell_type == "Focus"
        let isCantrip = keeper.spell_type == "Cantrip"
        let level = isCantrip ? 0 : (keeper.level ?? 1)
        let traditions = (keeper.tradition ?? []).compactMap { SpellTradition(rawValue: $0) }
        let tags = keeper.trait_raw ?? []

        var details = extractDetails(from: keeper.markdown ?? "")
        let speed: Int
        if let raw = keeper.actions, let mapped = actionSpeedMap[raw] {
            speed = mapped
        } else {
            speed = 4
            details += "\n\n* Special casting time: \(keeper.actions ?? "Unknown")"
        }
        if let legacy {
            let legacyDetails = extractDetails(from: legacy.markdown ?? "")
            if !legacyDetails.isEmpty {
                details += "\n\n== LEGACY ==\n\n" + legacyDetails
            }
        }

        return Spell(
            name: keeper.name,
            id: nil,
            level: level,
            isFocusSpell: isFocusSpell,
            details: details,
            aonID: aonID,
            traditions: traditions,
            speed: speed,
            range: AoNMarkupCleaner.stripLinks(keeper.range_raw ?? ""),
            area: AoNMarkupCleaner.stripLinks(keeper.area_raw ?? ""),
            tags: tags)
    }

    /// Everything after the header block, which may itself contain further `---`-separated
    /// segments (e.g. a trailing "Heightened" scaling note) — only the first `---` (which
    /// divides the structured header from the narrative body) should be dropped, not every
    /// occurrence, or later segments get discarded along with the main description.
    private static func extractDetails(from markdown: String) -> String {
        let parts = markdown.components(separatedBy: "\n---\n")
        var body = parts.count > 1 ? parts.dropFirst().joined(separator: "\n\n") : markdown
        body = AoNMarkupCleaner.stripLinks(body)
        body = body.replacingOccurrences(of: #"<br\s*/?>"#, with: "\n", options: .regularExpression)
        body = body.replacingOccurrences(of: #"</li>"#, with: "\n", options: .regularExpression)
        body = body.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
        return body.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
