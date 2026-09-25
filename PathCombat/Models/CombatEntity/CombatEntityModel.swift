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
    var role: CombatRole
    var actions: [CombatAction]


    init(name: String?, id: UUID?, tags: [String]?, level: Int?, iniMod: Int?, currentIni: Int?, hp: Int?, wounds: Int?,
         currentConditions: [String]?, ac: Int?, fortST: Int?, refST: Int?, willST: Int?, dc: Int?,
         affectingConditions: [AppliedCondition]? = nil, role: CombatRole? = nil, actions: [CombatAction]? = nil) {
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
        self.role = role ?? .attacker
        self.actions = actions ?? [CombatAction.defaultMelee()]
    }

    func copyForEncounter(name: String? = nil) -> EncounterCombatEntity {
        EncounterCombatEntity(
            id: nil,
            name: name ?? self.name,
            level: level,
            iniMod: iniMod,
            currentIni: 0,
            hp: hp,
            wounds: 0,
            tags: tags,
            currentConditions: [],
            affectingConditions: [],
            ac: ac,
            fortST: fortST,
            refST: refST,
            willST: willST,
            dc: dc,
            role: role,
            actions: actions)
    }

    func matchesSearch(_ query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let lowered = query.lowercased()
        if name.lowercased().contains(lowered) { return true }
        if let level = Int(query), self.level == level { return true }
        if tags.contains(where: { $0.lowercased().contains(lowered) }) { return true }
        if role.displayName.lowercased().contains(lowered) { return true }
        return false
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

extension CombatEntity: CombatEntityStats {}
