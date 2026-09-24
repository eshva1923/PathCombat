import Foundation

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

    /// SF Symbol shown before the entity's name in the initiative tracker.
    /// PC/Boss get a colored badge instead (see `Color.roleBadgeColor`), and minions get no marker.
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
