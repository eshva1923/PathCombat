//
//  CombatActionModel.swift
//  PathCombat
//
//  Created by Federico Brandani on 20/09/2026.
//

import Foundation
import SwiftData
/*
@Model
final class CombatAction {
    var name: String
    var abstract: String?
    var toHitModifier: Int = 0
    var damageDieRaw: String?
    var damageModifier: Int = 0
    var traits: [String] = []
    var actions: Int = 1
    
    init(name: String) {
        self.name = name
    }
    
    func rollToHit() -> Int {
        DieType.d20.roll() + toHitModifier
    }
    
    func rollDamage() -> Int {
        guard let damageDieRaw else { return 0 }
        return DieSet.init(fromString: damageDieRaw).roll() + (damageModifier)
    }
}
*/
