//
//  CombatEntityModel.swift
//  PathCombat
//
//  Created by Federico Brandani on 20/09/2026.
//

import Foundation
import SwiftData

@Model
final class CombatEntity: Equatable {
    var id: UUID
    var name: String
    var level: Int
    var iniMod: Int
    var currentIni: Int
    var hp: Int
    var wounds: Int
    var tags: [String]
    var currentConditions: [String]
    var affectingConditions: [AppliedCondition]
    var ac: Int
    var fortST: Int
    var refST: Int
    var willST: Int
    var dc: Int
    //var actions: [CombatAction] = []
    
    
    init(name: String?, id: UUID?, tags: [String]?, level: Int?, iniMod: Int?, currentIni: Int?, hp: Int?, wounds: Int?,
         currentConditions: [String]?, ac: Int?, fortST: Int?, refST: Int?, willST: Int?, dc: Int?,
         affectingConditions: [AppliedCondition]? = nil) {
        self.name = name ?? "Unnamed combatent"
        self.id = id ?? UUID()
        self.tags = tags ?? []
        self.level = level ?? 1
        self.iniMod = iniMod ?? 0
        self.currentIni = currentIni ?? 0
        self.hp = hp ?? 0
        self.wounds = wounds ?? 0
        self.currentConditions = currentConditions ?? []
        self.affectingConditions = affectingConditions ?? []
        self.ac = ac ?? 10
        self.fortST = fortST ?? 0
        self.refST = refST ?? 0
        self.willST = willST ?? 0
        self.dc = dc ?? 10
    }

    var isDead: Bool {
        wounds >= hp
    }

    /// Creates an independent copy of this entity (a fresh identity and reset combat state)
    /// so the same library template can be added to an encounter multiple times.
    func copyForEncounter(name: String? = nil) -> CombatEntity {
        CombatEntity(
            name: name ?? self.name,
            id: nil,
            tags: tags,
            level: level,
            iniMod: iniMod,
            currentIni: nil,
            hp: hp,
            wounds: nil,
            currentConditions: nil,
            ac: ac,
            fortST: fortST,
            refST: refST,
            willST: willST,
            dc: dc)
    }

    static func new() -> CombatEntity {
        CombatEntity(
            name: nil,
            id: nil,
            tags: nil,
            level: nil,
            iniMod: nil,
            currentIni: nil,
            hp: nil,
            wounds: nil,
            currentConditions: nil,
            ac: nil,
            fortST: nil,
            refST: nil,
            willST: nil,
            dc: nil)
    }
}
