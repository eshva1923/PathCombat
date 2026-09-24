//
//  EncounterViewModel.swift
//  PathCombat
//
//  Created by Federico Brandani on 23/09/2026.
//

import SwiftUI
import SwiftData

@Observable
final class EncounterViewModel {
    let encounter: Encounter

    init(encounter: Encounter) {
        self.encounter = encounter
    }

    var sortedByInitiative: [EncounterCombatEntity] {
        encounter.combatEntities.sorted { lhs, rhs in
            if lhs.currentIni != rhs.currentIni {
                return lhs.currentIni > rhs.currentIni
            }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    var dateAdded: String {
        encounter.date.formatted(date: .long, time: .shortened)
    }

    private static let uniquePerEncounterRoles: Set<CombatRole> = [.pc, .boss]

    func canAdd(_ template: CombatEntity) -> Bool {
        guard Self.uniquePerEncounterRoles.contains(template.role) else { return true }
        return !encounter.combatEntities.contains { $0.name == template.name }
    }

    func roleBadgeText(for entity: EncounterCombatEntity) -> String? {
        guard Self.uniquePerEncounterRoles.contains(entity.role) else { return nil }
        return entity.role.displayName
    }

    func roleIcon(for entity: EncounterCombatEntity) -> String? {
        entity.role.icon
    }

    var npcsNeedingInitiative: [EncounterCombatEntity] {
        encounter.combatEntities.filter { $0.currentIni == 0 && $0.role != .pc }
    }

    var needsNPCInitiativeRoll: Bool {
        !npcsNeedingInitiative.isEmpty
    }

    func rollInitiativeForNPCs() {
        withAnimation {
            for entity in npcsNeedingInitiative {
                entity.currentIni = DieType.d20.roll() + entity.iniMod
            }
        }
    }

    var canStartCombat: Bool {
        !encounter.combatEntities.isEmpty && !encounter.combatEntities.contains(where: { $0.currentIni == 0 })
    }

    var hasStartedCombat: Bool {
        encounter.actingEntity != nil
    }

    var isAdvanceButtonDisabled: Bool {
        if encounter.combatEntities.isEmpty { return true }
        if needsNPCInitiativeRoll { return false }
        return !canStartCombat
    }

    var advanceButtonColor: Color {
        if needsNPCInitiativeRoll {
            return .orange
        } else if !canStartCombat {
            return .red
        } else if hasStartedCombat {
            return .green
        } else {
            return .primary
        }
    }

    var advanceInitiativeButtonText: String {
        if needsNPCInitiativeRoll {
            return "Roll Initiative for NPCs"
        } else if hasStartedCombat {
            return "Turn \(encounter.elapsedCombatRounds)"
        } else {
            return "Start Combat"
        }
    }

    var advanceButtonHelpText: String {
        if needsNPCInitiativeRoll {
            return "Rolls initiative for every non-PC entity that hasn't rolled yet"
        } else if !canStartCombat {
            return "Every entity needs a non-zero initiative before combat can start"
        } else {
            return ""
        }
    }

    func woundSeverityColor(for entity: EncounterCombatEntity) -> Color {
        guard entity.hp > 0 else { return .primary }
        let ratio = Double(entity.wounds) / Double(entity.hp)
        switch ratio {
        case ..<0.25: return .primary
        case ..<0.5: return .green
        case ...0.75: return .orange
        default: return .red
        }
    }

    func rowBackground(for entity: EncounterCombatEntity) -> Color {
        if entity.isDead {
            return Color.black.opacity(0.35)
        } else if entity.id == encounter.actingEntity {
            return Color.secondary.opacity(0.25)
        } else {
            return Color.clear
        }
    }

    func conditionTagText(_ applied: AppliedCondition, allConditions: [Condition]) -> String {
        let name = allConditions.first(where: { $0.id == applied.conditionID })?.name ?? "Unknown"
        guard let value = applied.value else {
            return name
        }
        return "\(name) \(value)"
    }

    func conditionDescription(for applied: AppliedCondition, allConditions: [Condition]) -> String {
        allConditions.first(where: { $0.id == applied.conditionID })?.details ?? ""
    }

    func addEntity(from template: CombatEntity) {
        guard canAdd(template) else { return }
        withAnimation {
            let copy = template.copyForEncounter(name: nextAvailableName(for: template.name))
            encounter.combatEntities.append(copy)
        }
    }

    /// Counts how many copies of `template` are already in the encounter, matched by name
    /// family (e.g. "Skeleton", "Skeleton 2", ...). Only meaningful for non-unique roles;
    /// PC/Boss templates are capped at one by `canAdd` anyway.
    func addedCount(for template: CombatEntity) -> Int {
        encounter.combatEntities.filter { belongsToFamily($0.name, baseName: template.name) }.count
    }

    private func nextAvailableName(for baseName: String) -> String {
        let existingNumbers: [Int] = encounter.combatEntities.compactMap { entity in
            if entity.name == baseName {
                return 1
            }
            guard entity.name.hasPrefix("\(baseName) ") else { return nil }
            return Int(entity.name.dropFirst(baseName.count + 1))
        }
        guard let highest = existingNumbers.max() else { return baseName }
        return "\(baseName) \(highest + 1)"
    }

    private func belongsToFamily(_ name: String, baseName: String) -> Bool {
        name == baseName || name.hasPrefix("\(baseName) ")
    }

    func deleteEntity(_ entity: EncounterCombatEntity) {
        withAnimation {
            encounter.combatEntities.removeAll(where: { $0 == entity })
        }
    }

    func resetEncounter() {
        encounter.elapsedCombatRounds = 0
        encounter.currentInitiative = 0
        encounter.actingEntity = nil
    }
    
    func advanceInitiative() {
        let order = sortedByInitiative
        guard !order.isEmpty, let firstAlive = order.first(where: { !$0.isDead }) else { return }

        guard let actingID = encounter.actingEntity,
              let currentIndex = order.firstIndex(where: { $0.id == actingID }) else {
            encounter.currentInitiative = firstAlive.currentIni
            encounter.actingEntity = firstAlive.id
            return
        }

        var nextIndex = currentIndex
        var didWrap = false
        repeat {
            nextIndex += 1
            if nextIndex >= order.count {
                nextIndex = 0
                didWrap = true
            }
        } while order[nextIndex].isDead

        let next = order[nextIndex]
        encounter.currentInitiative = next.currentIni
        encounter.actingEntity = next.id
        if didWrap {
            encounter.elapsedCombatRounds += 1
        }
    }
}
