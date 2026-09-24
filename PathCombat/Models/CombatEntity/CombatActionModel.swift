//
//  CombatActionModel.swift
//  PathCombat
//
//  Created by Federico Brandani on 20/09/2026.
//

import Foundation

struct CombatAction: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var speed: Int
    var desc: String
    var target: ActionTarget
    var toHit: Int
    var damage: String

    init(id: UUID = UUID(), name: String, speed: Int = 1, desc: String = "",
         target: ActionTarget = .ac, toHit: Int = 0, damage: String = "") {
        self.id = id
        self.name = name
        self.speed = speed
        self.desc = desc
        self.target = target
        self.toHit = toHit
        self.damage = damage
    }

    static func defaultMelee() -> CombatAction {
        CombatAction(name: "Melee")
    }

    static let speedValues = [-1, 0, 1, 2, 3]

    static func speedSymbol(for speed: Int) -> String {
        switch speed {
        case -1: "􀅉"
        case 1: "􀋁"
        case 2: "􀋁􀋁"
        case 3: "􀋁􀋁􀋁"
        default: "􀋀"
        }
    }
    
    static func displayText(for speed: Int) -> String {
        switch speed {
        case -1: "Reaction"
        case 1: "Single action"
        case 2: "Two actions"
        case 3: "Three actions"
        default: "Free action"
        }
    }
    var displayText: String { Self.displayText(for: speed) }
    var speedSymbol: String { Self.speedSymbol(for: speed) }
}
