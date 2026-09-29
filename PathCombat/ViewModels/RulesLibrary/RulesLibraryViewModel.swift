//
//  RulesLibraryViewModel.swift
//  PathCombat
//
//  Created by Federico Brandani on 23/09/2026.
//

import SwiftUI
import SwiftData

enum RulesLibrarySection: Hashable {
    case conditions
    case actions
    case activities
}

@Observable
final class RulesLibraryViewModel {
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

    func damageText(for condition: Condition) -> String {
        condition.damage ?? ""
    }

    func setDamage(_ condition: Condition, to newValue: String) {
        condition.damage = newValue.trimmingCharacters(in: .whitespaces).isEmpty ? nil : newValue
    }

    func sortedConditions(_ conditions: [Condition]) -> [Condition] {
        conditions.sorted { $0.name < $1.name }
    }

    @discardableResult
    func addAction(kind: RuleActionKind, using modelContext: ModelContext) -> RuleAction {
        let newAction = RuleAction.new(kind: kind)
        withAnimation {
            modelContext.insert(newAction)
        }
        return newAction
    }

    func deleteAction(_ action: RuleAction, using modelContext: ModelContext) {
        withAnimation {
            modelContext.delete(action)
        }
    }

    func sortedActions(_ actions: [RuleAction], kind: RuleActionKind) -> [RuleAction] {
        actions.filter { $0.kind == kind }.sorted { $0.name < $1.name }
    }

    func updateTags(on action: RuleAction, from text: String) {
        action.tags = text
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    func section(for action: RuleAction) -> RulesLibrarySection {
        action.kind == .activity ? .activities : .actions
    }

    func navigationTitle(selectedID: UUID?, conditions: [Condition], actions: [RuleAction]) -> String {
        if let selectedID {
            if let condition = conditions.first(where: { $0.id == selectedID }) {
                return "\(AppSection.rulesAndConditions.rawValue) - \(condition.name)"
            }
            if let action = actions.first(where: { $0.id == selectedID }) {
                return "\(AppSection.rulesAndConditions.rawValue) - \(action.name)"
            }
        }
        return AppSection.rulesAndConditions.rawValue
    }
}
