//
//  CombatTrackerViewModel.swift
//  PathCombat
//
//  Created by Federico Brandani on 23/09/2026.
//

import SwiftUI
import SwiftData

@Observable
final class CombatTrackerViewModel {
    @discardableResult
    func addEncounter(using modelContext: ModelContext) -> Encounter {
        let newItem = Encounter(
            name: "New Encounter",
            id: nil,
            date: nil,
            completed: nil,
            combatEntities: nil)
        withAnimation {
            modelContext.insert(newItem)
        }
        return newItem
    }

    func deleteEncounter(_ encounter: Encounter, using modelContext: ModelContext) {
        withAnimation {
            modelContext.delete(encounter)
        }
    }
}
