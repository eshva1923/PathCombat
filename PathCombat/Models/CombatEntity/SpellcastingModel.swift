import Foundation

struct Spellcasting: Codable, Hashable {
    var focusPointsTotal: Int
    var focusPointsSpent: Int
    /// 10 entries: index 0 = rank 1 ... index 9 = rank 10 (cantrips need no slot).
    var availableSpellSlots: [Int]
    /// 10 entries, same indexing as `availableSpellSlots`.
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

    // Rank-based accessors hide the array/rank offset everywhere else in the codebase.
    // Cantrips (rank 0) need no spell slot, so slot accessors are no-ops for rank 0.
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

    /// Fresh copy for a new encounter: capabilities carry over, spent counters reset to full.
    func resetForEncounter() -> Spellcasting {
        var copy = self
        copy.focusPointsSpent = 0
        copy.spentSpellSlots = Array(repeating: 0, count: 10)
        return copy
    }
}
