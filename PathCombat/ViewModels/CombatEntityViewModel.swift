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
}
