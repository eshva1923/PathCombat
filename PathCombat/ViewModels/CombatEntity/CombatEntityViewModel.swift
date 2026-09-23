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
}
