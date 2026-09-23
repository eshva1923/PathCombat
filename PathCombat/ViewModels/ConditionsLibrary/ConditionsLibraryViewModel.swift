//
//  ConditionsLibraryViewModel.swift
//  PathCombat
//
//  Created by Federico Brandani on 23/09/2026.
//

import SwiftUI
import SwiftData

@Observable
final class ConditionsLibraryViewModel {
    @discardableResult
    func addCondition(using modelContext: ModelContext) -> Condition {
        let newCondition = Condition.new()
        withAnimation {
            modelContext.insert(newCondition)
        }
        return newCondition
    }

    func deleteCondition(_ condition: Condition, using modelContext: ModelContext) {
        withAnimation {
            modelContext.delete(condition)
        }
    }
}
