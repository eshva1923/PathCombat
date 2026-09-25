import SwiftUI
import SwiftData

struct SpellPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var librarySpells: [Spell]
    let isFocusSpell: Bool
    var level: Int? = nil
    let excludedSpellIDs: Set<UUID>
    let onAdd: (Spell) -> Void

    @State private var selectedSpellID: UUID?
    @State private var hoveredSpellID: UUID?
    @State private var searchText = ""

    private var availableSpells: [Spell] {
        librarySpells
            .filter { $0.isFocusSpell == isFocusSpell && !excludedSpellIDs.contains($0.id) }
            .filter { level == nil || $0.level == level }
            .filter { $0.matchesSearch(searchText) }
            .sorted { $0.level != $1.level ? $0.level < $1.level : $0.name < $1.name }
    }

    private var title: String {
        if isFocusSpell { return "Add Focus Spell" }
        guard let level else { return "Add Spell" }
        return level == 0 ? "Add Cantrip" : "Add Rank \(level) Spell"
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            HStack {
                Icons.search.foregroundStyle(.secondary)
                SelectAllTextField(text: $searchText)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            Divider()
            if availableSpells.isEmpty {
                Spacer()
                Text(searchText.isEmpty ? "No spells available in the library" : "No spells match \"\(searchText)\"")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(availableSpells) { spell in
                            spellRow(spell)
                            Divider()
                        }
                    }
                }
            }
            Divider()
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
                Button("Add") {
                    if let selectedSpellID,
                       let spell = availableSpells.first(where: { $0.id == selectedSpellID }) {
                        onAdd(spell)
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedSpellID == nil)
            }
            .padding()
        }
        .frame(minWidth: 440, minHeight: 380)
    }

    private func spellRow(_ spell: Spell) -> some View {
        Button {
            selectedSpellID = spell.id
        } label: {
            HStack {
                Text(spell.name)
                    .fontWeight(.semibold)
                Spacer()
                ForEach(spell.traditions) { tradition in
                    LabelTag(text: tradition.rawValue, color: .accentColor, imageName: nil, hoverEffect: false, hoverColor: nil)
                }
                if level == nil {
                    Icons.spellRank(spell.level)
                        .padding(3)
                        .background(Color.brown)
                        .cornerRadius(5)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .background(
            selectedSpellID == spell.id
                ? Color.accentColor.opacity(0.25)
                : (hoveredSpellID == spell.id ? Color.secondary.opacity(0.15) : Color.clear)
        )
        .onHover { hovering in
            hoveredSpellID = hovering ? spell.id : nil
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
