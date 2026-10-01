import Foundation
import SwiftData

enum AoNConditionImportService {
    private static let sourceFields = ["name", "markdown", "url", "legacy_id", "remaster_id", "release_date"]

    private struct ConditionSource: AoNVersionedSource {
        let name: String
        let markdown: String?
        let url: String?
        let legacy_id: [String]?
        let remaster_id: [String]?
        let release_date: String?
    }

    static func importConditions(context: ModelContext) async throws -> AoNImportResult {
        let sources: [ConditionSource] = try await AoNSearchClient.fetchAll(category: "condition", sourceFields: sourceFields)
        let keepers = AoNSearchClient.resolveKeepers(sources)

        let existing = try context.fetch(FetchDescriptor<Condition>())
        var existingByAonID: [Int: Condition] = [:]
        for condition in existing {
            if let aonID = condition.aonID {
                existingByAonID[aonID] = condition
            }
        }

        var imported = 0
        var skipped = 0
        for keeper in keepers {
            guard AoNSearchClient.isORC(keeper) else {
                skipped += 1
                continue
            }
            guard let mapped = makeCondition(from: keeper), let aonID = mapped.aonID else { continue }
            if let match = existingByAonID[aonID] {
                match.name = mapped.name
                match.details = mapped.details
                match.isPersistent = mapped.isPersistent
            } else {
                context.insert(mapped)
            }
            imported += 1
        }

        try context.save()
        return AoNImportResult(imported: imported, skipped: skipped)
    }

    private static func makeCondition(from keeper: ConditionSource) -> Condition? {
        guard let aonID = AoNSearchClient.aonID(from: keeper.url) else { return nil }

        let details = extractDetails(from: keeper.markdown ?? "")

        return Condition(
            name: keeper.name,
            id: nil,
            description: details,
            isPersistent: keeper.name == "Persistent Damage",
            aonID: aonID)
    }

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
