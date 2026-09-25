import SwiftUI
import SwiftData

enum SpellLibrarySection: Hashable {
    case cantrip
    case rank(Int)
    case focus
}

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

    /// Groups non-focus spells by rank; every focus spell (regardless of its own rank) is
    /// pulled into a single trailing "Focus" section instead, ordered by rank then name.
    func groupedSpells(_ spells: [Spell]) -> [(section: SpellLibrarySection, spells: [Spell])] {
        let focusSpells = spells.filter { $0.isFocusSpell }
        let rankedSpells = spells.filter { !$0.isFocusSpell }

        let grouped = Dictionary(grouping: rankedSpells, by: { $0.level })
        var result: [(section: SpellLibrarySection, spells: [Spell])] = grouped.keys.sorted().map { level in
            let section: SpellLibrarySection = level == 0 ? .cantrip : .rank(level)
            return (section, grouped[level, default: []].sorted { $0.name < $1.name })
        }

        if !focusSpells.isEmpty {
            let sortedFocus = focusSpells.sorted { $0.level != $1.level ? $0.level < $1.level : $0.name < $1.name }
            result.append((.focus, sortedFocus))
        }

        return result
    }

    func updateTags(on spell: Spell, from text: String) {
        spell.tags = text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
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
