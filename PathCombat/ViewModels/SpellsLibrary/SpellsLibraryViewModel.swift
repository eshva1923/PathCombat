import SwiftUI
import SwiftData

@Observable
final class SpellsLibraryViewModel {
    @discardableResult
    func addSpell(using modelContext: ModelContext) -> Spell {
        let newSpell = Spell.new()
        withAnimation {
            modelContext.insert(newSpell)
        }
        return newSpell
    }

    func deleteSpell(_ spell: Spell, using modelContext: ModelContext) {
        withAnimation {
            modelContext.delete(spell)
        }
    }

    func navigationTitle(selectedID: UUID?, in spells: [Spell]) -> String {
        if let selectedID,
           let spell = spells.first(where: { $0.id == selectedID }) {
            return "\(AppSection.spellsLibrary.rawValue) - \(spell.name)"
        }
        return AppSection.spellsLibrary.rawValue
    }

    func groupedByLevel(_ spells: [Spell]) -> [(level: Int, spells: [Spell])] {
        let grouped = Dictionary(grouping: spells, by: { $0.level })
        return grouped.keys.sorted().map { level in
            (level: level, spells: grouped[level, default: []].sorted { $0.name < $1.name })
        }
    }

    func toggleTradition(_ tradition: SpellTradition, on spell: Spell) {
        if let index = spell.traditions.firstIndex(of: tradition) {
            spell.traditions.remove(at: index)
        } else {
            spell.traditions.append(tradition)
        }
    }

    func duplicateNameWarning(for spell: Spell, in spells: [Spell]) -> String? {
        let trimmed = spell.name.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return nil }
        let hasDuplicate = spells.contains { other in
            other.id != spell.id && other.name.trimmingCharacters(in: .whitespaces).lowercased() == trimmed
        }
        return hasDuplicate ? "Another spell already uses the name \"\(spell.name)\"." : nil
    }

    func duplicateAonIDWarning(for spell: Spell, in spells: [Spell]) -> String? {
        guard let aonID = spell.aonID else { return nil }
        let hasDuplicate = spells.contains { other in
            other.id != spell.id && other.aonID == aonID
        }
        return hasDuplicate ? "Another spell already uses Archive of Nethys ID \(aonID)." : nil
    }
}
