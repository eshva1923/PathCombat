import Foundation
import SwiftData

@Model
final class Spell {
    @Attribute(.unique) var id: UUID
    var name: String
    var level: Int
    var isFocusSpell: Bool
    var details: String
    var aonID: Int?
    var traditions: [SpellTradition]

    init(name: String?, id: UUID?, level: Int?, isFocusSpell: Bool?, details: String?,
         aonID: Int? = nil, traditions: [SpellTradition]? = nil) {
        self.id = id ?? UUID()
        self.name = name ?? "Unnamed spell"
        self.level = level ?? 0
        self.isFocusSpell = isFocusSpell ?? false
        self.details = details ?? ""
        self.aonID = aonID
        self.traditions = traditions ?? []
    }

    static func new() -> Spell {
        Spell(name: nil, id: nil, level: nil, isFocusSpell: nil, details: nil)
    }

    var aonURL: URL? {
        guard let aonID else { return nil }
        return URL(string: "https://2e.aonprd.com/Spells.aspx?ID=\(aonID)")
    }

    func matchesSearch(_ query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let lowered = query.lowercased()
        if name.lowercased().contains(lowered) { return true }
        if let queryLevel = Int(query), level == queryLevel { return true }
        if traditions.contains(where: { $0.rawValue.lowercased().contains(lowered) }) { return true }
        return false
    }
}
