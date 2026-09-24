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

    func navigationTitle(selectedID: UUID?, in conditions: [Condition]) -> String {
        if let selectedID,
           let condition = conditions.first(where: { $0.id == selectedID }) {
            return "\(AppSection.rulesAndConditions.rawValue) - \(condition.name)"
        }
        return AppSection.rulesAndConditions.rawValue
    }
}
