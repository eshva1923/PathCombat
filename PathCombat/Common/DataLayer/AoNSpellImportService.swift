import Foundation
import SwiftData

struct SpellImportResult {
    let added: Int
    let alreadyPresent: Int
    let skippedLegacy: Int
}

enum AoNSpellImportService {
    private static let sourceFields = [
        "name", "level", "spell_type", "tradition", "actions", "range_raw", "area_raw", "target", "trait_raw",
        "url", "markdown", "legacy_id", "remaster_id", "release_date"
    ]

    private struct SpellSource: AoNVersionedSource {
        let name: String
        let level: Int?
        let spell_type: String?
        let tradition: [String]?
        let actions: String?
        let range_raw: String?
        let area_raw: String?
        let target: String?
        let trait_raw: [String]?
        let url: String?
        let markdown: String?
        let legacy_id: [String]?
        let remaster_id: [String]?
        let release_date: String?
    }

    static func importSpells(context: ModelContext) async throws -> SpellImportResult {
        let sources: [SpellSource] = try await AoNSearchClient.fetchAll(category: "spell", sourceFields: sourceFields)
        let keepers = AoNSearchClient.resolveKeepers(sources)

        let existing = try context.fetch(FetchDescriptor<Spell>())
        let existingAonIDs = Set(existing.compactMap(\.aonID))

        var added = 0
        var alreadyPresent = 0
        var skippedLegacy = 0
        for keeper in keepers {
            guard let aonID = AoNSearchClient.aonID(from: keeper.url) else { continue }
            guard AoNSearchClient.isORC(keeper) else {
                skippedLegacy += 1
                continue
            }
            guard !existingAonIDs.contains(aonID) else {
                alreadyPresent += 1
                continue
            }
            guard let mapped = makeSpell(from: keeper) else { continue }
            context.insert(mapped)
            added += 1
        }

        try context.save()
        return SpellImportResult(added: added, alreadyPresent: alreadyPresent, skippedLegacy: skippedLegacy)
    }

    private static func makeSpell(from keeper: SpellSource) -> Spell? {
        guard let aonID = AoNSearchClient.aonID(from: keeper.url) else { return nil }

        let isFocusSpell = keeper.spell_type == "Focus"
        let level = keeper.level ?? 1
        let traditions = (keeper.tradition ?? []).compactMap { SpellTradition(rawValue: $0) }
        let tags = keeper.trait_raw ?? []

        var details = extractDetails(from: keeper.markdown ?? "")
        let speed: Int
        if let raw = keeper.actions, let mapped = AoNMarkupCleaner.actionCostMap[raw] {
            speed = mapped
        } else {
            speed = 4
            details += "\n\n* Special casting time: \(keeper.actions ?? "Unknown")"
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
            target: AoNMarkupCleaner.stripLinks(keeper.target ?? ""),
            tags: tags)
    }

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
