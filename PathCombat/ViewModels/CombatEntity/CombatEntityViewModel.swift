//
//  CombatEntityViewModel.swift
//  PathCombat
//
//  Created by Federico Brandani on 23/09/2026.
//

import Foundation
import Observation

@Observable
final class CombatEntityViewModel {
    let combatEntity: CombatEntity

    init(combatEntity: CombatEntity) {
        self.combatEntity = combatEntity
    }

    func rollInitiative() {
        combatEntity.currentIni = DieType.d20.roll() + combatEntity.iniMod
    }

    func addCondition(_ condition: Condition, value: Int?) {
        guard !combatEntity.affectingConditions.contains(where: { $0.conditionID == condition.id }) else {
            return
        }
        combatEntity.affectingConditions.append(AppliedCondition(conditionID: condition.id, value: value))
    }

    func removeCondition(_ applied: AppliedCondition) {
        combatEntity.affectingConditions.removeAll(where: { $0.id == applied.id })
    }

    func conditionName(for applied: AppliedCondition, allConditions: [Condition]) -> String {
        allConditions.first(where: { $0.id == applied.conditionID })?.name ?? "Unknown condition"
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

    func updateTags(from text: String) {
        combatEntity.tags = text
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
