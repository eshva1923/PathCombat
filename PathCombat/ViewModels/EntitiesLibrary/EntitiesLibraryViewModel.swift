//
//  EntitiesLibraryViewModel.swift
//  PathCombat
//
//  Created by Federico Brandani on 23/09/2026.
//

import SwiftUI
import SwiftData

@Observable
final class EntitiesLibraryViewModel {
    @discardableResult
    func addEntity(using modelContext: ModelContext) -> CombatEntity {
        let newEntity = CombatEntity.new()
        withAnimation {
            modelContext.insert(newEntity)
        }
        return newEntity
    }

    func deleteEntity(_ entity: CombatEntity, using modelContext: ModelContext) {
        withAnimation {
            modelContext.delete(entity)
        }
    }

    func navigationTitle(selectedID: UUID?, in entities: [CombatEntity]) -> String {
        if let selectedID,
           let entity = entities.first(where: { $0.id == selectedID }) {
            return "\(AppSection.entitiesLibrary.rawValue) - \(entity.name)"
        }
        return AppSection.entitiesLibrary.rawValue
    }

    /// Groups entities by role (PC first, then the rest alphabetically by display name),
    /// with entities inside each section sorted by level descending, then name ascending.
    func groupedEntities(_ entities: [CombatEntity]) -> [(role: CombatRole, entities: [CombatEntity])] {
        let grouped = Dictionary(grouping: entities, by: { $0.role })
        let roles = grouped.keys.sorted { lhs, rhs in
            if lhs == .pc { return true }
            if rhs == .pc { return false }
            return lhs.displayName < rhs.displayName
        }
        return roles.map { role in
            let sorted = grouped[role, default: []].sorted {
                $0.level != $1.level ? $0.level > $1.level : $0.name < $1.name
            }
            return (role, sorted)
        }
    }
}
