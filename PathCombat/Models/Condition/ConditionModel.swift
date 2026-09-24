//
//  ConditionModel.swift
//  PathCombat
//
//  Created by Federico Brandani on 23/09/2026.
//

import Foundation
import SwiftData

@Model
final class Condition {
    var id: UUID
    var name: String
    var details: String
    var isPersistent: Bool
    var damage: String?

    init(name: String?, id: UUID?, description: String?, isPersistent: Bool? = nil, damage: String? = nil) {
        self.id = id ?? UUID()
        self.name = name ?? "Unnamed condition"
        self.details = description ?? ""
        self.isPersistent = isPersistent ?? false
        self.damage = damage
    }

    static func new() -> Condition {
        Condition(name: nil, id: nil, description: nil)
    }

    func matchesSearch(_ query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let lowered = query.lowercased()
        if name.lowercased().contains(lowered) { return true }
        if let damage, damage.lowercased().contains(lowered) { return true }
        return false
    }
}
