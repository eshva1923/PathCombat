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

    func addEntity(from template: CombatEntity) {
        withAnimation {
            let copy = template.copyForEncounter(name: nextAvailableName(for: template.name))
            encounter.combatEntities.append(copy)
        }
    }

    private func nextAvailableName(for baseName: String) -> String {
        let existingNumbers: [Int] = encounter.combatEntities.compactMap { entity in
            if entity.name == baseName {
                return 1
            }
            guard entity.name.hasPrefix("\(baseName) ") else { return nil }
            return Int(entity.name.dropFirst(baseName.count + 1))
        }
        guard let highest = existingNumbers.max() else { return baseName }
        return "\(baseName) \(highest + 1)"
    }

    func deleteEntity(_ entity: CombatEntity) {
        withAnimation {
            encounter.combatEntities.removeAll(where: { $0 == entity })
        }
    }

    func resetEncounter() {
        encounter.elapsedCombatRounds = 0
        encounter.currentInitiative = 0
        encounter.actingEntity = nil
    }
    
    func advanceInitiative() {
        let order = sortedByInitiative
        guard !order.isEmpty, let firstAlive = order.first(where: { !$0.isDead }) else { return }

        guard let actingID = encounter.actingEntity,
              let currentIndex = order.firstIndex(where: { $0.id == actingID }) else {
            encounter.currentInitiative = firstAlive.currentIni
            encounter.actingEntity = firstAlive.id
            return
        }

        var nextIndex = currentIndex
        var didWrap = false
        repeat {
            nextIndex += 1
            if nextIndex >= order.count {
                nextIndex = 0
                didWrap = true
            }
        } while order[nextIndex].isDead

        let next = order[nextIndex]
        encounter.currentInitiative = next.currentIni
        encounter.actingEntity = next.id
        if didWrap {
            encounter.elapsedCombatRounds += 1
        }
    }
}
