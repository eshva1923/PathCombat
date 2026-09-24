//
//  AppliedConditionModel.swift
//  PathCombat
//
//  Created by Federico Brandani on 23/09/2026.
//

import Foundation

struct AppliedCondition: Codable, Identifiable, Hashable {
    var id: UUID
    var conditionID: UUID
    var value: Int?
    var damage: String?

    init(id: UUID = UUID(), conditionID: UUID, value: Int? = nil, damage: String? = nil) {
        self.id = id
        self.conditionID = conditionID
        self.value = value
        self.damage = damage
    }
}
