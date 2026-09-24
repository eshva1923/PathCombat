import Foundation
import SwiftData

/// A per-encounter copy of a `CombatEntity` template, with its own identity and combat
/// state (initiative, wounds, applied conditions). Kept as a distinct type (rather than a
/// flag on `CombatEntity`) so it can never leak into library/picker queries by mistake.
@Model
final class EncounterCombatEntity: Equatable {
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

    init(id: UUID?, name: String, level: Int, iniMod: Int, currentIni: Int, hp: Int, wounds: Int,
         tags: [String], currentConditions: [String], affectingConditions: [AppliedCondition],
         ac: Int, fortST: Int, refST: Int, willST: Int, dc: Int, role: CombatRole) {
        self.id = id ?? UUID()
        self.name = name
        self.level = level
        self.iniMod = iniMod
        self.currentIni = currentIni
        self.hp = hp
        self.wounds = wounds
        self.tags = tags
        self.currentConditions = currentConditions
        self.affectingConditions = affectingConditions
        self.ac = ac
        self.fortST = fortST
        self.refST = refST
        self.willST = willST
        self.dc = dc
        self.role = role
    }
}

extension EncounterCombatEntity: CombatEntityStats {}
