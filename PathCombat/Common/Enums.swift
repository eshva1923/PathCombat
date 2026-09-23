//
//  Enums.swift
//  PathCombat
//
//  Created by Federico Brandani on 20/09/2026.
//

enum Difficulty: String {
    case Trivial = "Trivial"
    case Low = "Low"
    case Moderate = "Moderate"
    case Severe = "Severe"
    case Extreme = "Extreme"
    case Deadly = "Deadly"
}

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
