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
    var totalHP: Int
    var currentHP: Int
    var tags: [String]
    var currentConditions: [String]
    var ac: Int
    var fortST: Int
    var refST: Int
    var willST: Int
    var dc: Int
    //var actions: [CombatAction] = []
    
    
    init(name: String?, id: UUID?, tags: [String]?, level: Int?, iniMod: Int?, currentIni: Int?, totalHP: Int?, currentHP: Int?,
         currentConditions: [String]?, ac: Int?, fortST: Int?, refST: Int?, willST: Int?, dc: Int?) {
        self.name = name ?? "Unnamed combatent"
        self.id = id ?? UUID()
        self.tags = tags ?? []
        self.level = level ?? 1
        self.iniMod = iniMod ?? 0
        self.currentIni = currentIni ?? 0
        self.totalHP = totalHP ?? 0
        self.currentHP = currentHP ?? totalHP ?? 0
        self.currentConditions = currentConditions ?? []
        self.ac = ac ?? 10
        self.fortST = fortST ?? 0
        self.refST = refST ?? 0
        self.willST = willST ?? 0
        self.dc = dc ?? 10
    }
    
    static func new() -> CombatEntity {
        CombatEntity(
            name: nil,
            id: nil,
            tags: nil,
            level: nil,
            iniMod: nil,
            currentIni: nil,
            totalHP: nil,
            currentHP: nil,
            currentConditions: nil,
            ac: nil,
            fortST: nil,
            refST: nil,
            willST: nil,
            dc: nil)
    }
}
