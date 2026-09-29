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

enum DataBackupService {
    private static let conditionsMarker = "#Conditions"
    private static let spellsMarker = "#Spells"
    private static let actionsMarker = "#Actions"
    private static let entitiesMarker = "#Entities"
    private static let encounterEntitiesMarker = "#EncounterEntities"
    private static let encountersMarker = "#Encounters"

    private static let conditionsHeader = ["id", "name", "details", "damage", "isPersistent", "aonID"]
    private static let spellsHeader = ["id", "name", "level", "isFocusSpell", "details", "aonID", "traditions", "speed", "range", "area", "tags", "target"]
    private static let actionsHeader = ["id", "name", "kind", "speed", "details", "tags", "aonID"]
    private static let entityStatsHeader = [
        "id", "name", "tags", "level", "iniMod", "currentIni", "hp", "wounds",
        "affectingConditions", "ac", "fortST", "refST", "willST", "dc", "role", "actions", "spellcasting",
        "speed", "size", "sourceEntityID"
    ]
    private static let encountersHeader = [
        "id", "name", "date", "completed", "currentInitiative", "elapsedCombatRounds",
        "actingEntity", "combatEntityIDs", "session", "tags"
    ]

    private static let dateFormatter = ISO8601DateFormatter()

    static func exportCSV(context: ModelContext) throws -> String {
        let conditions = try context.fetch(FetchDescriptor<Condition>())
        let spells = try context.fetch(FetchDescriptor<Spell>())
        let actions = try context.fetch(FetchDescriptor<RuleAction>())
        let entities = try context.fetch(FetchDescriptor<CombatEntity>())
        let encounterEntities = try context.fetch(FetchDescriptor<EncounterCombatEntity>())
        let encounters = try context.fetch(FetchDescriptor<Encounter>())

        var lines: [String] = []

        lines.append(conditionsMarker)
        lines.append(CSVWriter.row(conditionsHeader))
        for condition in conditions {
            lines.append(CSVWriter.row([
                condition.id.uuidString, condition.name, condition.details, condition.damage ?? "",
                condition.isPersistent ? "true" : "false", condition.aonID.map(String.init) ?? ""
            ]))
        }
        lines.append("")

        lines.append(spellsMarker)
        lines.append(CSVWriter.row(spellsHeader))
        for spell in spells {
            lines.append(CSVWriter.row(spellRow(for: spell)))
        }
        lines.append("")

        lines.append(actionsMarker)
        lines.append(CSVWriter.row(actionsHeader))
        for action in actions {
            lines.append(CSVWriter.row(actionRow(for: action)))
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
                encounter.combatEntities.map(\.id.uuidString).joined(separator: ";"),
                String(encounter.session),
                encounter.tags.joined(separator: ";")
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

    static func wipeSpells(context: ModelContext) throws {
        try context.delete(model: Spell.self)
        try context.save()
    }

    static func wipeActions(context: ModelContext) throws {
        try context.delete(model: RuleAction.self)
        try context.save()
    }

    static func wipeAll(context: ModelContext) throws {
        try context.delete(model: Encounter.self)
        try context.delete(model: EncounterCombatEntity.self)
        try context.delete(model: CombatEntity.self)
        try context.delete(model: Condition.self)
        try context.delete(model: Spell.self)
        try context.delete(model: RuleAction.self)
        try context.save()
    }

    static func importCSV(_ text: String, context: ModelContext) throws {
        let sections = try parseSections(text)

        try context.delete(model: Encounter.self)
        try context.delete(model: EncounterCombatEntity.self)
        try context.delete(model: CombatEntity.self)
        try context.delete(model: Condition.self)
        try context.delete(model: Spell.self)
        try context.delete(model: RuleAction.self)

        for row in sections[conditionsMarker] ?? [] {
            guard row.count >= 3, let id = UUID(uuidString: row[0]) else { continue }
            let damage = row.count >= 4 && !row[3].isEmpty ? row[3] : nil
            let isPersistent = row.count >= 5 ? row[4] == "true" : nil
            let aonID = row.count >= 6 && !row[5].isEmpty ? Int(row[5]) : nil
            context.insert(Condition(name: row[1], id: id, description: row[2], isPersistent: isPersistent, damage: damage, aonID: aonID))
        }

        for row in sections[spellsMarker] ?? [] {
            guard let spell = parseSpell(from: row) else { continue }
            context.insert(spell)
        }

        for row in sections[actionsMarker] ?? [] {
            guard let action = parseAction(from: row) else { continue }
            context.insert(action)
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
                actingEntity: UUID(uuidString: row[6]),
                session: row.count >= 9 ? Int(row[8]) : nil,
                tags: row.count >= 10 ? splitList(row[9]) : nil))
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
            encode(entity.affectingConditions),
            String(entity.ac),
            String(entity.fortST),
            String(entity.refST),
            String(entity.willST),
            String(entity.dc),
            entity.role.rawValue,
            encodeActions(entity.actions),
            encodeSpellcasting(entity.spellcasting),
            encodeSpeed(entity.speed),
            entity.size.rawValue,
            entity.sourceEntityID?.uuidString ?? ""
        ]
    }

    private static func parseCombatEntity(from row: [String]) -> CombatEntity? {
        guard row.count >= 14, let id = UUID(uuidString: row[0]) else { return nil }
        return CombatEntity(
            name: row[1],
            id: id,
            tags: splitList(row[2]),
            level: Int(row[3]),
            iniMod: Int(row[4]),
            currentIni: Int(row[5]),
            hp: Int(row[6]),
            wounds: Int(row[7]),
            ac: Int(row[9]),
            fortST: Int(row[10]),
            refST: Int(row[11]),
            willST: Int(row[12]),
            dc: Int(row[13]),
            affectingConditions: decodeAppliedConditions(row[8]),
            role: row.count >= 15 ? CombatRole(rawValue: row[14]) : nil,
            actions: row.count >= 16 ? decodeActions(row[15]) : nil,
            spellcasting: row.count >= 17 ? decodeSpellcasting(row[16]) : nil,
            speed: row.count >= 18 ? decodeSpeed(row[17]) : nil,
            size: row.count >= 19 ? CreatureSize(rawValue: row[18]) : nil)
    }

    private static func parseEncounterCombatEntity(from row: [String]) -> EncounterCombatEntity? {
        guard row.count >= 14, let id = UUID(uuidString: row[0]) else { return nil }
        return EncounterCombatEntity(
            id: id,
            name: row[1],
            level: Int(row[3]) ?? 1,
            iniMod: Int(row[4]) ?? 0,
            currentIni: Int(row[5]) ?? 0,
            hp: Int(row[6]) ?? 0,
            wounds: Int(row[7]) ?? 0,
            tags: splitList(row[2]),
            affectingConditions: decodeAppliedConditions(row[8]),
            ac: Int(row[9]) ?? 10,
            fortST: Int(row[10]) ?? 0,
            refST: Int(row[11]) ?? 0,
            willST: Int(row[12]) ?? 0,
            dc: Int(row[13]) ?? 10,
            role: row.count >= 15 ? (CombatRole(rawValue: row[14]) ?? .attacker) : .attacker,
            actions: row.count >= 16 ? decodeActions(row[15]) : [],
            spellcasting: row.count >= 17 ? decodeSpellcasting(row[16]) : nil,
            speed: row.count >= 18 ? decodeSpeed(row[17]) : Speed.defaultLandSpeed,
            size: row.count >= 19 ? (CreatureSize(rawValue: row[18]) ?? .medium) : .medium,
            sourceEntityID: row.count >= 20 ? UUID(uuidString: row[19]) : nil)
    }

    private static func spellRow(for spell: Spell) -> [String] {
        [
            spell.id.uuidString,
            spell.name,
            String(spell.level),
            spell.isFocusSpell ? "true" : "false",
            spell.details,
            spell.aonID.map(String.init) ?? "",
            spell.traditions.map(\.rawValue).joined(separator: ";"),
            String(spell.speed),
            spell.range,
            spell.area,
            spell.tags.joined(separator: ";"),
            spell.target
        ]
    }

    private static func parseSpell(from row: [String]) -> Spell? {
        guard row.count >= 5, let id = UUID(uuidString: row[0]) else { return nil }
        let aonID = row.count >= 6 && !row[5].isEmpty ? Int(row[5]) : nil
        let traditions = row.count >= 7 ? splitList(row[6]).compactMap { SpellTradition(rawValue: $0) } : []
        return Spell(
            name: row[1],
            id: id,
            level: Int(row[2]),
            isFocusSpell: row[3] == "true",
            details: row[4],
            aonID: aonID,
            traditions: traditions,
            speed: row.count >= 8 ? Int(row[7]) : nil,
            range: row.count >= 9 ? row[8] : nil,
            area: row.count >= 10 ? row[9] : nil,
            target: row.count >= 12 ? row[11] : nil,
            tags: row.count >= 11 ? splitList(row[10]) : nil)
    }

    private static func actionRow(for action: RuleAction) -> [String] {
        [
            action.id.uuidString,
            action.name,
            action.kind.rawValue,
            action.speed.map(String.init) ?? "",
            action.details,
            action.tags.joined(separator: ";"),
            action.aonID.map(String.init) ?? ""
        ]
    }

    private static func parseAction(from row: [String]) -> RuleAction? {
        guard row.count >= 5, let id = UUID(uuidString: row[0]) else { return nil }
        let speed = row[3].isEmpty ? nil : Int(row[3])
        let tags = row.count >= 6 ? splitList(row[5]) : []
        let aonID = row.count >= 7 && !row[6].isEmpty ? Int(row[6]) : nil
        return RuleAction(
            name: row[1],
            id: id,
            kind: RuleActionKind(rawValue: row[2]),
            speed: speed,
            details: row[4],
            tags: tags,
            aonID: aonID)
    }

    private static func splitList(_ value: String) -> [String] {
        value.isEmpty ? [] : value.split(separator: ";").map(String.init)
    }

    private static func encode(_ applied: [AppliedCondition]) -> String {
        guard let data = try? JSONEncoder().encode(applied) else { return "[]" }
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    private static func encodeActions(_ actions: [CombatAction]) -> String {
        guard let data = try? JSONEncoder().encode(actions) else { return "[]" }
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    private static func decodeActions(_ value: String) -> [CombatAction] {
        guard !value.isEmpty, let data = value.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([CombatAction].self, from: data)) ?? []
    }

    private static func encodeSpellcasting(_ spellcasting: Spellcasting?) -> String {
        guard let spellcasting, let data = try? JSONEncoder().encode(spellcasting) else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }

    private static func decodeSpellcasting(_ value: String) -> Spellcasting? {
        guard !value.isEmpty, let data = value.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(Spellcasting.self, from: data)
    }

    private static func encodeSpeed(_ speed: [Speed]) -> String {
        guard let data = try? JSONEncoder().encode(speed) else { return "[]" }
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    private static func decodeSpeed(_ value: String) -> [Speed] {
        guard !value.isEmpty, let data = value.data(using: .utf8) else { return Speed.defaultLandSpeed }
        return (try? JSONDecoder().decode([Speed].self, from: data)) ?? Speed.defaultLandSpeed
    }

    private static func decodeAppliedConditions(_ value: String) -> [AppliedCondition] {
        guard !value.isEmpty, let data = value.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([AppliedCondition].self, from: data)) ?? []
    }

    private static func parseSections(_ text: String) throws -> [String: [[String]]] {
        let requiredMarkers = [conditionsMarker, entitiesMarker, encounterEntitiesMarker, encountersMarker]
        let allMarkers = requiredMarkers + [spellsMarker, actionsMarker]
        let rows = CSVParser.parseRows(text)

        var sections: [String: [[String]]] = [:]
        var currentMarker: String?
        var isHeaderRow = false

        for row in rows {
            guard let first = row.first, !first.isEmpty || row.count > 1 else { continue }
            if row.count == 1, allMarkers.contains(row[0]) {
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

        guard requiredMarkers.allSatisfy({ sections[$0] != nil }) else {
            throw DataBackupError.invalidFormat
        }

        return sections
    }
}
