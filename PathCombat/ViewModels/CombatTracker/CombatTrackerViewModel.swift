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

    func navigationTitle(selectedID: UUID?, in encounters: [Encounter]) -> String {
        if let selectedID,
           let encounter = encounters.first(where: { $0.id == selectedID }) {
            return "\(AppSection.combatTracker.rawValue) - \(encounter.name)"
        }
        return AppSection.combatTracker.rawValue
    }

    func groupedBySession(_ encounters: [Encounter]) -> [(session: Int, encounters: [Encounter])] {
        let grouped = Dictionary(grouping: encounters, by: { $0.session })
        return grouped.keys.sorted(by: >).map { session in
            (session: session, encounters: grouped[session, default: []].sorted { $0.date < $1.date })
        }
    }
}
