//
//  Enums.swift
//  PathCombat
//
//  Created by Federico Brandani on 20/09/2026.
//

enum DieType: Int {
    case d2 = 2
    case d4 = 4
    case d6 = 6
    case d8 = 8
    case d10 = 10
    case d12 = 12
    case d20 = 20
    
    func roll() -> Int {
        Int.random(in: 1...self.rawValue)
    }
}

enum AppSection: String, CaseIterable, Identifiable {
    case combatTracker = "Combat Tracker"
    case entitiesLibrary = "Entities Library"
    case rulesAndConditions = "Rules and Conditions"

    var id: Self { self }

    var systemImage: String {
        switch self {
        case .combatTracker: return "shield.lefthalf.filled"
        case .entitiesLibrary: return "person.3.fill"
        case .rulesAndConditions: return "book.closed.fill"
        }
    }
}

enum ActionTarget: String, Codable, CaseIterable, Identifiable {
    case ac = "AC"
    case fortitudeSave
    case reflexSave
    case willSave

    var id: Self { self }

    var displayName: String {
        switch self {
        case .ac: "AC"
        case .fortitudeSave: "Fortitude Save"
        case .reflexSave: "Reflex Save"
        case .willSave: "Will Save"
        }
    }
}

enum CombatRole: String, Codable, CaseIterable, Identifiable {
    case spellcaster, attacker, tank, support, pc, boss, minion

    var id: Self { self }

    var displayName: String {
        switch self {
        case .spellcaster: "Spellcaster"
        case .attacker: "Attacker"
        case .tank: "Tank"
        case .support: "Support"
        case .pc: "PC"
        case .boss: "Boss"
        case .minion: "Minion"
        }
    }

    var icon: String? {
        switch self {
        case .spellcaster: "wand.and.sparkles.inverse"
        case .attacker: "figure.fencing"
        case .tank: "shield.pattern.checkered"
        case .support: "cross.fill"
        case .pc: "figure.mixed.cardio"
        case .boss: "figure.strengthtraining.traditional"
        case .minion: "figure.and.child.holdinghands"
        }
    }
}
