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
}
