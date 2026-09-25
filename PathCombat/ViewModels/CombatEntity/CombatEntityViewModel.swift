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

    func speedText() -> String {
        combatEntity.speed.map { $0.displayText }.joined(separator: ", ")
    }

    func setSpeed(from text: String) {
        combatEntity.speed = Speed.parseList(text)
    }

    func addAction() {
        combatEntity.actions.append(CombatAction(name: "New Action"))
    }

    func removeAction(_ action: CombatAction) {
        combatEntity.actions.removeAll(where: { $0.id == action.id })
    }

    func action(withID id: UUID) -> CombatAction? {
        combatEntity.actions.first(where: { $0.id == id })
    }

    func updateAction(_ action: CombatAction) {
        guard let index = combatEntity.actions.firstIndex(where: { $0.id == action.id }) else {
            return
        }
        combatEntity.actions[index] = action
    }

    func nonStackableConditionIDs(allConditions: [Condition]) -> Set<UUID> {
        Set(combatEntity.affectingConditions.compactMap { applied -> UUID? in
            let condition = allConditions.first(where: { $0.id == applied.conditionID })
            return (condition?.isPersistent ?? false) ? nil : applied.conditionID
        })
    }

    func enableSpellcasting() {
        if combatEntity.spellcasting == nil {
            combatEntity.spellcasting = Spellcasting()
        }
    }

    func disableSpellcasting() {
        combatEntity.spellcasting = nil
    }

    func focusPointsTotal() -> Int {
        combatEntity.spellcasting?.focusPointsTotal ?? 0
    }

    func setFocusPointsTotal(_ value: Int) {
        combatEntity.spellcasting?.focusPointsTotal = value
    }

    func focusPointsSpent() -> Int {
        combatEntity.spellcasting?.focusPointsSpent ?? 0
    }

    func setFocusPointsSpent(_ value: Int) {
        guard let total = combatEntity.spellcasting?.focusPointsTotal else { return }
        combatEntity.spellcasting?.focusPointsSpent = min(max(0, value), total)
    }

    func availableSlots(rank: Int) -> Int {
        combatEntity.spellcasting?.availableSlots(rank: rank) ?? 0
    }

    func setAvailableSlots(rank: Int, to value: Int) {
        combatEntity.spellcasting?.setAvailableSlots(rank: rank, to: value)
    }

    func spentSlots(rank: Int) -> Int {
        combatEntity.spellcasting?.spentSlots(rank: rank) ?? 0
    }

    func setSpentSlots(rank: Int, to value: Int) {
        combatEntity.spellcasting?.setSpentSlots(rank: rank, to: value)
    }

    func knownSpells(rank: Int, allSpells: [Spell]) -> [Spell] {
        guard let ids = combatEntity.spellcasting?.knownSpellIDs else { return [] }
        return allSpells.filter { ids.contains($0.id) && $0.level == rank }
    }

    func focusSpells(allSpells: [Spell]) -> [Spell] {
        guard let ids = combatEntity.spellcasting?.focusSpellIDs else { return [] }
        return allSpells.filter { ids.contains($0.id) }
    }

    func addSpell(_ spell: Spell) {
        combatEntity.spellcasting?.addSpell(spell.id)
    }

    func removeSpell(_ spell: Spell) {
        combatEntity.spellcasting?.removeSpell(spell.id)
    }

    func addFocusSpell(_ spell: Spell) {
        combatEntity.spellcasting?.addFocusSpell(spell.id)
    }

    func removeFocusSpell(_ spell: Spell) {
        combatEntity.spellcasting?.removeFocusSpell(spell.id)
    }
}
