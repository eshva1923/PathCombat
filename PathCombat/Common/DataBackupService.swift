import Foundation
import SwiftData

enum DataBackupError: LocalizedError {
    case invalidFormat

    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "This file doesn't look like a PathCombat backup."
        }
    }
}

/// Exports/imports the whole SwiftData store (conditions, entities, encounters) as a single
/// multi-section CSV file: each section starts with a "#Marker" line, followed by a header
/// row and its data rows.
enum DataBackupService {
    private static let conditionsMarker = "#Conditions"
    private static let entitiesMarker = "#Entities"
    private static let encountersMarker = "#Encounters"

    private static let conditionsHeader = ["id", "name", "details"]
    private static let entitiesHeader = [
        "id", "name", "tags", "level", "iniMod", "currentIni", "hp", "wounds",
        "currentConditions", "affectingConditions", "ac", "fortST", "refST", "willST", "dc"
    ]
    private static let encountersHeader = [
        "id", "name", "date", "completed", "currentInitiative", "elapsedCombatRounds",
        "actingEntity", "combatEntityIDs"
    ]

    private static let dateFormatter = ISO8601DateFormatter()

    static func exportCSV(context: ModelContext) throws -> String {
        let conditions = try context.fetch(FetchDescriptor<Condition>())
        let entities = try context.fetch(FetchDescriptor<CombatEntity>())
        let encounters = try context.fetch(FetchDescriptor<Encounter>())

        var lines: [String] = []

        lines.append(conditionsMarker)
        lines.append(CSVWriter.row(conditionsHeader))
        for condition in conditions {
            lines.append(CSVWriter.row([condition.id.uuidString, condition.name, condition.details]))
        }
        lines.append("")

        lines.append(entitiesMarker)
        lines.append(CSVWriter.row(entitiesHeader))
        for entity in entities {
            lines.append(CSVWriter.row([
                entity.id.uuidString,
                entity.name,
                entity.tags.joined(separator: ";"),
                String(entity.level),
                String(entity.iniMod),
                String(entity.currentIni),
                String(entity.hp),
                String(entity.wounds),
                entity.currentConditions.joined(separator: ";"),
                encode(entity.affectingConditions),
                String(entity.ac),
                String(entity.fortST),
                String(entity.refST),
                String(entity.willST),
                String(entity.dc)
            ]))
        }
        lines.append("")

        lines.append(encountersMarker)
        lines.append(CSVWriter.row(encountersHeader))
        for encounter in encounters {
            lines.append(CSVWriter.row([
                encounter.id.uuidString,
                encounter.name,
                dateFormatter.string(from: encounter.date),
                encounter.completed ? "true" : "false",
                String(encounter.currentInitiative),
                String(encounter.elapsedCombatRounds),
                encounter.actingEntity?.uuidString ?? "",
                encounter.combatEntities.map(\.id.uuidString).joined(separator: ";")
            ]))
        }

        return lines.joined(separator: "\n")
    }

    /// Deletes all existing encounters, entities, and conditions, then recreates them from the CSV.
    static func importCSV(_ text: String, context: ModelContext) throws {
        let sections = try parseSections(text)

        try context.delete(model: Encounter.self)
        try context.delete(model: CombatEntity.self)
        try context.delete(model: Condition.self)

        for row in sections[conditionsMarker] ?? [] {
            guard row.count >= 3, let id = UUID(uuidString: row[0]) else { continue }
            context.insert(Condition(name: row[1], id: id, description: row[2]))
        }

        var entitiesByID: [UUID: CombatEntity] = [:]
        for row in sections[entitiesMarker] ?? [] {
            guard row.count >= 15, let id = UUID(uuidString: row[0]) else { continue }
            let entity = CombatEntity(
                name: row[1],
                id: id,
                tags: splitList(row[2]),
                level: Int(row[3]),
                iniMod: Int(row[4]),
                currentIni: Int(row[5]),
                hp: Int(row[6]),
                wounds: Int(row[7]),
                currentConditions: splitList(row[8]),
                ac: Int(row[10]),
                fortST: Int(row[11]),
                refST: Int(row[12]),
                willST: Int(row[13]),
                dc: Int(row[14]),
                affectingConditions: decodeAppliedConditions(row[9]))
            context.insert(entity)
            entitiesByID[id] = entity
        }

        for row in sections[encountersMarker] ?? [] {
            guard row.count >= 8, let id = UUID(uuidString: row[0]) else { continue }
            let combatEntities = splitList(row[7]).compactMap { UUID(uuidString: $0) }.compactMap { entitiesByID[$0] }
            context.insert(Encounter(
                name: row[1],
                id: id,
                date: dateFormatter.date(from: row[2]),
                completed: row[3] == "true",
                combatEntities: combatEntities,
                currentInitiative: Int(row[4]),
                elapsedCombatRounds: Int(row[5]),
                actingEntity: UUID(uuidString: row[6])))
        }

        try context.save()
    }

    private static func splitList(_ value: String) -> [String] {
        value.isEmpty ? [] : value.split(separator: ";").map(String.init)
    }

    private static func encode(_ applied: [AppliedCondition]) -> String {
        applied
            .map { "\($0.id.uuidString)|\($0.conditionID.uuidString)|\($0.value.map(String.init) ?? "")" }
            .joined(separator: ";")
    }

    private static func decodeAppliedConditions(_ value: String) -> [AppliedCondition] {
        guard !value.isEmpty else { return [] }
        return value.split(separator: ";").compactMap { chunk -> AppliedCondition? in
            let parts = chunk.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            guard parts.count == 3, let id = UUID(uuidString: parts[0]), let conditionID = UUID(uuidString: parts[1]) else {
                return nil
            }
            return AppliedCondition(id: id, conditionID: conditionID, value: Int(parts[2]))
        }
    }

    private static func parseSections(_ text: String) throws -> [String: [[String]]] {
        let markers = [conditionsMarker, entitiesMarker, encountersMarker]
        let rows = CSVParser.parseRows(text)

        var sections: [String: [[String]]] = [:]
        var currentMarker: String?
        var isHeaderRow = false

        for row in rows {
            guard let first = row.first, !first.isEmpty || row.count > 1 else { continue }
            if row.count == 1, markers.contains(row[0]) {
                currentMarker = row[0]
                isHeaderRow = true
                sections[row[0]] = []
                continue
            }
            guard let currentMarker else { continue }
            if isHeaderRow {
                isHeaderRow = false
                continue
            }
            sections[currentMarker, default: []].append(row)
        }

        guard markers.allSatisfy({ sections[$0] != nil }) else {
            throw DataBackupError.invalidFormat
        }

        return sections
    }
}
