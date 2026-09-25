import Foundation
import SwiftData

/// Imports the Pathfinder 2e condition list from Archive of Nethys's public search index.
enum AoNConditionImportService {
    private static let sourceFields = ["name", "markdown", "url", "id", "legacy_id", "remaster_id"]

    private struct ConditionSource: AoNVersionedSource {
        let name: String
        let markdown: String?
        let url: String?
        let id: String
        let legacy_id: [String]?
        let remaster_id: [String]?
    }

    /// Fetches the current condition list and upserts it into the store, matching existing
    /// conditions by `aonID`. Conditions already imported get every field refreshed from
    /// AoN; conditions you created yourself (no matching `aonID`) are never touched. Returns
    /// the number of conditions processed.
    static func importConditions(context: ModelContext, includeLegacyDescriptions: Bool = false) async throws -> Int {
        let sources: [ConditionSource] = try await AoNSearchClient.fetchAll(category: "condition", sourceFields: sourceFields)
        let pairs = AoNSearchClient.resolveKeepersWithLegacy(sources)

        let existing = try context.fetch(FetchDescriptor<Condition>())
        var existingByAonID: [Int: Condition] = [:]
        for condition in existing {
            if let aonID = condition.aonID {
                existingByAonID[aonID] = condition
            }
        }

        var count = 0
        for (keeper, legacy) in pairs {
            let legacyToMerge = includeLegacyDescriptions ? legacy : nil
            guard let mapped = makeCondition(from: keeper, legacy: legacyToMerge), let aonID = mapped.aonID else { continue }
            if let match = existingByAonID[aonID] {
                match.name = mapped.name
                match.details = mapped.details
                match.isPersistent = mapped.isPersistent
            } else {
                context.insert(mapped)
            }
            count += 1
        }

        try context.save()
        return count
    }

    private static func makeCondition(from keeper: ConditionSource, legacy: ConditionSource?) -> Condition? {
        guard let aonID = AoNSearchClient.aonID(from: keeper.url) else { return nil }

        var details = extractDetails(from: keeper.markdown ?? "")
        if let legacy {
            let legacyDetails = extractDetails(from: legacy.markdown ?? "")
            if !legacyDetails.isEmpty {
                details += "\n\n== LEGACY ==\n\n" + legacyDetails
            }
        }

        return Condition(
            name: keeper.name,
            id: nil,
            description: details,
            isPersistent: keeper.name == "Persistent Damage",
            aonID: aonID)
    }

    /// Drops the `<title level="1">...</title>` header and `**Source** ... pg. N` line, then
    /// promotes nested `<title level="2" ...>Heading</title>` markers (as seen in Persistent
    /// Damage's much longer body) into bold sub-headings *before* generic tag stripping, so
    /// they survive as visually distinct paragraphs instead of collapsing into one wall of text.
    private static func extractDetails(from markdown: String) -> String {
        var body = markdown
        body = body.replacingOccurrences(of: #"<title level="1"[^>]*>.*?</title>"#, with: "", options: .regularExpression)
        body = body.replacingOccurrences(of: #"\*\*Source\*\*[^\n]*\n?"#, with: "", options: .regularExpression)
        body = body.replacingOccurrences(of: #"<title level="2"[^>]*>(.*?)</title>"#, with: "\n\n**$1**\n", options: .regularExpression)
        body = AoNMarkupCleaner.stripLinks(body)
        body = body.replacingOccurrences(of: #"<br\s*/?>"#, with: "\n", options: .regularExpression)
        body = body.replacingOccurrences(of: #"</li>"#, with: "\n", options: .regularExpression)
        body = body.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
        return body.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
