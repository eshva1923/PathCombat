//
//  EncounterViewModel.swift
//  PathCombat
//
//  Created by Federico Brandani on 23/09/2026.
//

import SwiftUI
import SwiftData

@Observable
final class EncounterViewModel {
    let encounter: Encounter

    init(encounter: Encounter) {
        self.encounter = encounter
    }

    var sortedByInitiative: [CombatEntity] {
        encounter.combatEntities.sorted { lhs, rhs in
            if lhs.currentIni != rhs.currentIni {
                return lhs.currentIni > rhs.currentIni
            }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    var dateAdded: String {
        encounter.date.formatted(date: .long, time: .shortened)
    }

    func addNewEntity() {
        withAnimation {
            encounter.combatEntities.append(CombatEntity.new())
        }
    }

    func addExistingEntity(_ entity: CombatEntity) {
        withAnimation {
            encounter.combatEntities.append(entity)
        }
    }

    func deleteEntity(_ entity: CombatEntity) {
        withAnimation {
            encounter.combatEntities.removeAll(where: { $0 == entity })
        }
    }

    func advanceInitiative() {
        let order = sortedByInitiative
        guard !order.isEmpty else { return }

        guard encounter.currentInitiative != 0,
              let actingID = encounter.actingEntity,
              let currentIndex = order.firstIndex(where: { $0.id == actingID }) else {
            let first = order.first!
            encounter.currentInitiative = first.currentIni
            encounter.actingEntity = first.id
            return
        }

        let nextIndex = currentIndex + 1
        if nextIndex < order.count {
            let next = order[nextIndex]
            encounter.currentInitiative = next.currentIni
            encounter.actingEntity = next.id
        } else {
            let first = order.first!
            encounter.currentInitiative = first.currentIni
            encounter.actingEntity = first.id
            encounter.elapsedCombatRounds += 1
        }
    }
}
