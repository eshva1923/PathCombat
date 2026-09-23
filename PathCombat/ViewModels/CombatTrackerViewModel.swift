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
    func addEncounter(using modelContext: ModelContext) {
        withAnimation {
            let newItem = Encounter(
                name: "New Encounter",
                id: nil,
                date: nil,
                completed: nil,
                combatEntities: nil)
            modelContext.insert(newItem)
        }
    }

    func deleteEncounter(_ encounter: Encounter, using modelContext: ModelContext) {
        withAnimation {
            modelContext.delete(encounter)
        }
    }
}
