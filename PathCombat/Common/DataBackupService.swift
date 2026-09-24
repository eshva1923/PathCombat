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

/// Exports/imports the whole SwiftData store (conditions, entity templates, encounter-owned
/// entity copies, encounters) as a single multi-section CSV file: each section starts with a
/// "#Marker" line, followed by a header row and its data rows.
enum DataBackupService {
    private static let conditionsMarker = "#Conditions"
    private static let entitiesMarker = "#Entities"
    private static let encounterEntitiesMarker = "#EncounterEntities"
    private static let encountersMarker = "#Encounters"

    private static let conditionsHeader = ["id", "name", "details"]
    private static let entityStatsHeader = [
        "id", "name", "tags", "level", "iniMod", "currentIni", "hp", "wounds",
        "currentConditions", "affectingConditions", "ac", "fortST", "refST", "willST", "dc", "role"
    ]
    private static let encountersHeader = [
        "id", "name", "date", "completed", "currentInitiative", "elapsedCombatRounds",
        "actingEntity", "combatEntityIDs"
    ]

    private static let dateFormatter = ISO8601DateFormatter()

    static func exportCSV(context: ModelContext) throws -> String {
        let conditions = try context.fetch(FetchDescriptor<Condition>())
        let entities = try context.fetch(FetchDescriptor<CombatEntity>())
        let encounterEntities = try context.fetch(FetchDescriptor<EncounterCombatEntity>())
        let encounters = try context.fetch(FetchDescriptor<Encounter>())

        var lines: [String] = []

        lines.append(conditionsMarker)
        lines.append(CSVWriter.row(conditionsHeader))
        for condition in conditions {
            lines.append(CSVWriter.row([condition.id.uuidString, condition.name, condition.details]))
        }
        lines.append("")

        lines.append(entitiesMarker)
        lines.append(CSVWriter.row(entityStatsHeader))
        for entity in entities {
            lines.append(CSVWriter.row(entityStatsRow(for: entity)))
        }
        lines.append("")

        lines.append(encounterEntitiesMarker)
        lines.append(CSVWriter.row(entityStatsHeader))
        for entity in encounterEntities {
            lines.append(CSVWriter.row(entityStatsRow(for: entity)))
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

    static func wipeEncounters(context: ModelContext) throws {
        try context.delete(model: Encounter.self)
        try context.save()
    }

    static func wipeEntities(context: ModelContext) throws {
        try context.delete(model: CombatEntity.self)
        try context.save()
    }

    static func wipeConditions(context: ModelContext) throws {
        try context.delete(model: Condition.self)
        try context.save()
    }

    static func wipeAll(context: ModelContext) throws {
        try context.delete(model: Encounter.self)
        try context.delete(model: EncounterCombatEntity.self)
        try context.delete(model: CombatEntity.self)
        try context.delete(model: Condition.self)
        try context.save()
    }

    /// Deletes all existing encounters, entities, and conditions, then recreates them from the CSV.
    static func importCSV(_ text: String, context: ModelContext) throws {
        let sections = try parseSections(text)

        try context.delete(model: Encounter.self)
        try context.delete(model: EncounterCombatEntity.self)
        try context.delete(model: CombatEntity.self)
        try context.delete(model: Condition.self)

        for row in sections[conditionsMarker] ?? [] {
            guard row.count >= 3, let id = UUID(uuidString: row[0]) else { continue }
            context.insert(Condition(name: row[1], id: id, description: row[2]))
        }

        for row in sections[entitiesMarker] ?? [] {
            guard let entity = parseCombatEntity(from: row) else { continue }
            context.insert(entity)
        }

        var encounterEntitiesByID: [UUID: EncounterCombatEntity] = [:]
        for row in sections[encounterEntitiesMarker] ?? [] {
            guard let id = row.first.flatMap(UUID.init(uuidString:)), let entity = parseEncounterCombatEntity(from: row) else { continue }
            context.insert(entity)
            encounterEntitiesByID[id] = entity
        }

        for row in sections[encountersMarker] ?? [] {
            guard row.count >= 8, let id = UUID(uuidString: row[0]) else { continue }
            let combatEntities = splitList(row[7]).compactMap { UUID(uuidString: $0) }.compactMap { encounterEntitiesByID[$0] }
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

    private static func entityStatsRow(for entity: CombatEntityStats) -> [String] {
        [
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
            String(entity.dc),
            entity.role.rawValue
        ]
    }

    private static func parseCombatEntity(from row: [String]) -> CombatEntity? {
        guard row.count >= 15, let id = UUID(uuidString: row[0]) else { return nil }
        return CombatEntity(
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
            affectingConditions: decodeAppliedConditions(row[9]),
            role: row.count >= 16 ? CombatRole(rawValue: row[15]) : nil)
    }

    private static func parseEncounterCombatEntity(from row: [String]) -> EncounterCombatEntity? {
        guard row.count >= 15, let id = UUID(uuidString: row[0]) else { return nil }
        return EncounterCombatEntity(
            id: id,
            name: row[1],
            level: Int(row[3]) ?? 1,
            iniMod: Int(row[4]) ?? 0,
            currentIni: Int(row[5]) ?? 0,
            hp: Int(row[6]) ?? 0,
            wounds: Int(row[7]) ?? 0,
            tags: splitList(row[2]),
            currentConditions: splitList(row[8]),
            affectingConditions: decodeAppliedConditions(row[9]),
            ac: Int(row[10]) ?? 10,
            fortST: Int(row[11]) ?? 0,
            refST: Int(row[12]) ?? 0,
            willST: Int(row[13]) ?? 0,
            dc: Int(row[14]) ?? 10,
            role: row.count >= 16 ? (CombatRole(rawValue: row[15]) ?? .attacker) : .attacker)
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
        let markers = [conditionsMarker, entitiesMarker, encounterEntitiesMarker, encountersMarker]
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
