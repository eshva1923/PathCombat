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
    func addEntity(using modelContext: ModelContext) {
        withAnimation {
            modelContext.insert(CombatEntity.new())
        }
    }

    func deleteEntity(_ entity: CombatEntity, using modelContext: ModelContext) {
        withAnimation {
            modelContext.delete(entity)
        }
    }
}
