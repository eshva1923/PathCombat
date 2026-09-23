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

    init(name: String?, id: UUID?, description: String?) {
        self.id = id ?? UUID()
        self.name = name ?? "Unnamed condition"
        self.details = description ?? ""
    }

    static func new() -> Condition {
        Condition(name: nil, id: nil, description: nil)
    }
}
