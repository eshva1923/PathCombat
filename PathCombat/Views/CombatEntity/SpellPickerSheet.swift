import SwiftUI
import SwiftData

struct SpellPickerSheet: View {
    @Query private var librarySpells: [Spell]
    let isFocusSpell: Bool
    var level: Int? = nil
    let excludedSpellIDs: Set<UUID>
    let onAdd: (Spell) -> Void

    @State private var selectedSpellID: UUID?
    @State private var searchText = ""

    private var availableSpells: [Spell] {
        librarySpells
            .filter { $0.isFocusSpell == isFocusSpell && !excludedSpellIDs.contains($0.id) }
            .filter { level == nil || $0.matchesRank(level ?? 0) }
            .filter { $0.matchesSearch(searchText) }
            .sorted { $0.level != $1.level ? $0.level < $1.level : $0.name < $1.name }
    }

    private var title: String {
        if isFocusSpell { return "Add Focus Spell" }
        guard let level else { return "Add Spell" }
        return level == 0 ? "Add Cantrip" : "Add Rank \(level) Spell"
    }

    var body: some View {
        PickerSheet(
            title: title,
            searchText: $searchText,
            isEmpty: availableSpells.isEmpty,
            emptyMessage: pickerSheetEmptyMessage(noun: "spells", searchText: searchText),
            isAddDisabled: selectedSpellID == nil,
            onAdd: {
                if let selectedSpellID, let spell = availableSpells.first(where: { $0.id == selectedSpellID }) {
                    onAdd(spell)
                }
            },
            accessory: { EmptyView() },
            listContent: {
                LazyVStack(spacing: 0) {
                    ForEach(availableSpells) { spell in
                        spellRow(spell)
                        Divider()
                    }
                }
            },
            footer: { EmptyView() }
        )
    }

    private func spellRow(_ spell: Spell) -> some View {
        LibraryRow(isSelected: selectedSpellID == spell.id, onSelect: { selectedSpellID = spell.id }) {
            HStack {
                Text(spell.name)
                    .fontWeight(.semibold)
                Spacer()
                ForEach(spell.traditions) { tradition in
                    LabelTag(text: tradition.rawValue, color: .accentColor)
                }
                if level == nil {
                    Icons.spellRank(spell.level)
                        .padding(3)
                        .background(Color.brown)
                        .cornerRadius(5)
                }
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Spell.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    container.mainContext.insert(Spell(name: "Ancient Dust", id: nil, level: 3, isFocusSpell: false, details: "", traditions: [.primal]))
    container.mainContext.insert(Spell(name: "Cinder Gaze", id: nil, level: 0, isFocusSpell: true, details: "", traditions: [.arcane]))
    return SpellPickerSheet(isFocusSpell: false, excludedSpellIDs: [], onAdd: { _ in })
        .modelContainer(container)
}
