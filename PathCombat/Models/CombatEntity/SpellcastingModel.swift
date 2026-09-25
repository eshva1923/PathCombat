import Foundation

struct Spellcasting: Codable, Hashable {
    var focusPointsTotal: Int
    var focusPointsSpent: Int
    var availableSpellSlots: [Int]
    var spentSpellSlots: [Int]
    var knownSpellIDs: [UUID]
    var focusSpellIDs: [UUID]

    init(focusPointsTotal: Int = 0, focusPointsSpent: Int = 0,
         availableSpellSlots: [Int]? = nil, spentSpellSlots: [Int]? = nil,
         knownSpellIDs: [UUID] = [], focusSpellIDs: [UUID] = []) {
        self.focusPointsTotal = focusPointsTotal
        self.focusPointsSpent = focusPointsSpent
        self.availableSpellSlots = availableSpellSlots ?? Array(repeating: 0, count: 10)
        self.spentSpellSlots = spentSpellSlots ?? Array(repeating: 0, count: 10)
        self.knownSpellIDs = knownSpellIDs
        self.focusSpellIDs = focusSpellIDs
    }

    func availableSlots(rank: Int) -> Int { rank > 0 ? availableSpellSlots[rank - 1] : 0 }
    func spentSlots(rank: Int) -> Int { rank > 0 ? spentSpellSlots[rank - 1] : 0 }

    mutating func setAvailableSlots(rank: Int, to value: Int) {
        guard rank > 0 else { return }
        availableSpellSlots[rank - 1] = max(0, value)
    }

    mutating func setSpentSlots(rank: Int, to value: Int) {
        guard rank > 0 else { return }
        spentSpellSlots[rank - 1] = min(max(0, value), availableSpellSlots[rank - 1])
    }

    mutating func addSpell(_ id: UUID) {
        guard !knownSpellIDs.contains(id) else { return }
        knownSpellIDs.append(id)
    }

    mutating func removeSpell(_ id: UUID) {
        knownSpellIDs.removeAll { $0 == id }
    }

    mutating func addFocusSpell(_ id: UUID) {
        guard !focusSpellIDs.contains(id) else { return }
        focusSpellIDs.append(id)
    }

    mutating func removeFocusSpell(_ id: UUID) {
        focusSpellIDs.removeAll { $0 == id }
    }

    func resetForEncounter() -> Spellcasting {
        var copy = self
        copy.focusPointsSpent = 0
        copy.spentSpellSlots = Array(repeating: 0, count: 10)
        return copy
    }

    static func synced(template: Spellcasting?, existing: Spellcasting?) -> Spellcasting? {
        guard var result = template else { return nil }
        if let existing {
            result.focusPointsSpent = min(existing.focusPointsSpent, result.focusPointsTotal)
            for rank in 1...10 {
                result.setSpentSlots(rank: rank, to: min(existing.spentSlots(rank: rank), result.availableSlots(rank: rank)))
            }
        }
        return result
    }
}
