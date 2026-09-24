//
//  Encounter.swift
//  PathCombat
//
//  Created by Federico Brandani on 19/09/2026.
//

import Foundation
import SwiftData

@Model
final class Encounter {
    var id: UUID
    var date: Date
    var name: String
    var completed: Bool
    var combatEntities: [EncounterCombatEntity]
    var currentInitiative: Int = 0
    var elapsedCombatRounds: Int = 0
    var actingEntity: UUID?
    var session: Int
    var tags: [String]

    init(name: String, id: UUID?, date: Date?, completed: Bool?, combatEntities: [EncounterCombatEntity]?,
         currentInitiative: Int? = nil, elapsedCombatRounds: Int? = nil, actingEntity: UUID? = nil,
         session: Int? = nil, tags: [String]? = nil) {
        self.id = id ?? UUID()
        self.name = name
        self.date = date ?? Date()
        self.completed = completed ?? false
        self.combatEntities = combatEntities ?? []
        self.currentInitiative = currentInitiative ?? 0
        self.elapsedCombatRounds = elapsedCombatRounds ?? 0
        self.actingEntity = actingEntity
        self.session = session ?? 0
        self.tags = tags ?? []
    }

    func formatDate() -> String {
        self.date.formatted()
    }

    func matchesSearch(_ query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let lowered = query.lowercased()
        if name.lowercased().contains(lowered) { return true }
        if let querySession = Int(query), session == querySession { return true }
        if tags.contains(where: { $0.lowercased().contains(lowered) }) { return true }
        return false
    }
}
