import Foundation
import SwiftData

/// Imports Pathfinder 2e actions and activities from Archive of Nethys's public search index.
/// AoN has no separate "activity" category: activities are action documents tagged Exploration
/// or Downtime; everything else is a plain action.
enum AoNActionImportService {
    private static let sourceFields = ["name", "actions", "trait_raw", "markdown", "url", "id", "legacy_id", "remaster_id"]
    private static let activityTraits: Set<String> = ["Exploration", "Downtime"]

    private struct ActionSource: AoNVersionedSource {
        let name: String
        let actions: String?
        let trait_raw: [String]?
        let markdown: String?
        let url: String?
        let id: String
        let legacy_id: [String]?
        let remaster_id: [String]?
    }

    struct ImportCounts {
        let actions: Int
        let activities: Int
    }

    /// Fetches the current action list and upserts it into the store, matching existing
    /// entries by `aonID`. Entries already imported get every field refreshed from AoN;
    /// entries you created yourself (no matching `aonID`) are never touched.
    static func importActions(context: ModelContext, includeLegacyDescriptions: Bool = false) async throws -> ImportCounts {
        let sources: [ActionSource] = try await AoNSearchClient.fetchAll(category: "action", sourceFields: sourceFields)
        let pairs = AoNSearchClient.resolveKeepersWithLegacy(sources)

        let existing = try context.fetch(FetchDescriptor<RuleAction>())
        var existingByAonID: [Int: RuleAction] = [:]
        for action in existing {
            if let aonID = action.aonID {
                existingByAonID[aonID] = action
            }
        }

        var actionCount = 0
        var activityCount = 0
        for (keeper, legacy) in pairs {
            let legacyToMerge = includeLegacyDescriptions ? legacy : nil
            guard let mapped = makeRuleAction(from: keeper, legacy: legacyToMerge), let aonID = mapped.aonID else { continue }
            if let match = existingByAonID[aonID] {
                match.name = mapped.name
                match.kind = mapped.kind
                match.speed = mapped.speed
                match.details = mapped.details
                match.tags = mapped.tags
            } else {
                context.insert(mapped)
            }
            if mapped.kind == .activity {
                activityCount += 1
            } else {
                actionCount += 1
            }
        }

        try context.save()
        return ImportCounts(actions: actionCount, activities: activityCount)
    }

    private static func makeRuleAction(from keeper: ActionSource, legacy: ActionSource?) -> RuleAction? {
        guard let aonID = AoNSearchClient.aonID(from: keeper.url) else { return nil }

        let tags = keeper.trait_raw ?? []
        let kind: RuleActionKind = tags.contains(where: activityTraits.contains) ? .activity : .action

        var details = extractDetails(from: keeper.markdown ?? "")
        var speed: Int?
        if let raw = keeper.actions {
            if let mapped = AoNMarkupCleaner.actionCostMap[raw] {
                speed = mapped
            } else {
                speed = 4
                details += "\n\n* Special cost: \(raw)"
            }
        }
        if let legacy {
            let legacyDetails = extractDetails(from: legacy.markdown ?? "")
            if !legacyDetails.isEmpty {
                details += "\n\n== LEGACY ==\n\n" + legacyDetails
            }
        }

        return RuleAction(
            name: keeper.name,
            id: nil,
            kind: kind,
            speed: speed,
            details: details,
            tags: tags,
            aonID: aonID)
    }

    /// Everything up to the first `---` is the structured header (title, traits, source, and —
    /// for reactions/activities with prerequisites — Trigger/Requirements). Title, traits, and
    /// Source are dropped as noise; Trigger/Requirements are kept and joined with the body.
    private static func extractDetails(from markdown: String) -> String {
        let parts = markdown.components(separatedBy: "\n---\n")
        var header = parts[0]
        let body = parts.count > 1 ? parts.dropFirst().joined(separator: "\n\n") : ""

        header = header.replacingOccurrences(of: #"<title level="1"[^>]*>.*?</title>"#, with: "", options: .regularExpression)
        header = header.replacingOccurrences(of: #"<traits>[\s\S]*?</traits>"#, with: "", options: .regularExpression)
        header = header.replacingOccurrences(of: #"\*\*Source\*\*[^\n]*\n?"#, with: "", options: .regularExpression)
        header = header.replacingOccurrences(of: #"</?column[^>]*>"#, with: "", options: .regularExpression)
        header = header.trimmingCharacters(in: .whitespacesAndNewlines)

        var combined = header
        if !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            combined += (combined.isEmpty ? "" : "\n\n") + body
        }

        combined = AoNMarkupCleaner.stripLinks(combined)
        combined = combined.replacingOccurrences(of: #"<br\s*/?>"#, with: "\n", options: .regularExpression)
        combined = combined.replacingOccurrences(of: #"</li>"#, with: "\n", options: .regularExpression)
        combined = combined.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
        return combined.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
