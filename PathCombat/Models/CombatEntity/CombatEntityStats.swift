import Foundation
import Observation

protocol CombatEntityStats: AnyObject, Observable {
    var id: UUID { get }
    var name: String { get set }
    var level: Int { get set }
    var iniMod: Int { get set }
    var currentIni: Int { get set }
    var hp: Int { get set }
    var wounds: Int { get set }
    var tags: [String] { get set }
    var currentConditions: [String] { get set }
    var affectingConditions: [AppliedCondition] { get set }
    var ac: Int { get set }
    var fortST: Int { get set }
    var refST: Int { get set }
    var willST: Int { get set }
    var dc: Int { get set }
    var role: CombatRole { get set }
    var actions: [CombatAction] { get set }
    var spellcasting: Spellcasting? { get set }
    var speed: [Speed] { get set }
    var size: CreatureSize { get set }
    /// The library `CombatEntity` this instance was copied from, if any. Always `nil` for a
    /// template itself; set on `EncounterCombatEntity` copies so "Sync to Encounters" can find them.
    var sourceEntityID: UUID? { get }
}

extension CombatEntityStats {
    var isDead: Bool { wounds >= hp }
}
