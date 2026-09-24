//
//  CombatEntityViewModel.swift
//  PathCombat
//
//  Created by Federico Brandani on 23/09/2026.
//

import Foundation
import Observation
import SwiftUI

@Observable
final class CombatEntityViewModel<Entity: CombatEntityStats> {
    let combatEntity: Entity

    init(combatEntity: Entity) {
        self.combatEntity = combatEntity
    }

    func rollInitiative() {
        combatEntity.currentIni = DieType.d20.roll() + combatEntity.iniMod
    }

    func addCondition(_ condition: Condition, value: Int?, damage: String? = nil) {
        if !condition.isPersistent {
            guard !combatEntity.affectingConditions.contains(where: { $0.conditionID == condition.id }) else {
                return
            }
        }
        combatEntity.affectingConditions.append(AppliedCondition(conditionID: condition.id, value: value, damage: damage))
    }

    func removeCondition(_ applied: AppliedCondition) {
        combatEntity.affectingConditions.removeAll(where: { $0.id == applied.id })
    }

    func conditionTagText(for applied: AppliedCondition, allConditions: [Condition]) -> String {
        guard let condition = allConditions.first(where: { $0.id == applied.conditionID }) else {
            return "Unknown condition"
        }
        if let damage = applied.damage {
            return "\(condition.name) \(damage)"
        }
        guard let value = applied.value else {
            return condition.name
        }
        return "\(condition.name) \(value)"
    }

    func conditionDescription(for applied: AppliedCondition, allConditions: [Condition]) -> String {
        allConditions.first(where: { $0.id == applied.conditionID })?.details ?? ""
    }

    func isPersistentDamage(for applied: AppliedCondition, allConditions: [Condition]) -> Bool {
        allConditions.first(where: { $0.id == applied.conditionID })?.isPersistent ?? false
    }

    func conditionTagColor(for applied: AppliedCondition, allConditions: [Condition]) -> Color {
        isPersistentDamage(for: applied, allConditions: allConditions) ? .darkRed : .orange
    }

    func sortedConditions(_ conditions: [AppliedCondition], allConditions: [Condition]) -> [AppliedCondition] {
        conditions.sorted { lhs, rhs in
            let lhsPersistent = isPersistentDamage(for: lhs, allConditions: allConditions)
            let rhsPersistent = isPersistentDamage(for: rhs, allConditions: allConditions)
            return !lhsPersistent && rhsPersistent
        }
    }

    func conditionValueText(for applied: AppliedCondition) -> String {
        applied.value.map(String.init) ?? "-"
    }

    func setConditionValue(_ applied: AppliedCondition, to newValue: String) {
        guard let index = combatEntity.affectingConditions.firstIndex(where: { $0.id == applied.id }) else {
            return
        }
        combatEntity.affectingConditions[index].value = Int(newValue)
    }

    func conditionDamageText(for applied: AppliedCondition) -> String {
        applied.damage ?? ""
    }

    func setConditionDamage(_ applied: AppliedCondition, to newValue: String) {
        guard let index = combatEntity.affectingConditions.firstIndex(where: { $0.id == applied.id }) else {
            return
        }
        combatEntity.affectingConditions[index].damage = newValue.isEmpty ? nil : newValue
    }

    func updateTags(from text: String) {
        combatEntity.tags = text
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    func addAction() {
        combatEntity.actions.append(CombatAction(name: "New Action"))
    }

    func removeAction(_ action: CombatAction) {
        combatEntity.actions.removeAll(where: { $0.id == action.id })
    }
}
