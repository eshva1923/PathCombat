import SwiftUI
import SwiftData

struct SpellsLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var spells: [Spell]
    @State private var viewModel = SpellsLibraryViewModel()
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var hoveredSpellID: UUID?
    @State private var selectedSpellID: UUID?
    @State private var searchText = ""

    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    private enum Constants {
        static let minSplitViewWidth = 180.0
        static let idealSplitViewWidth = 200.0
        static let maxSplitViewWidth = 220.0
    }

    private var groupedSpells: [(level: Int, spells: [Spell])] {
        viewModel.groupedByLevel(spells.filter { $0.matchesSearch(searchText) })
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            VStack(spacing: 0) {
                searchField
                Divider()
                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        ForEach(groupedSpells, id: \.level) { group in
                            levelHeader(group.level)
                            ForEach(group.spells) { spell in
                                spellRow(spell)
                                Divider()
                            }
                        }
                        addSpellRow
                    }
                }
            }
            .navigationSplitViewColumnWidth(
                min: Constants.minSplitViewWidth,
                ideal: Constants.idealSplitViewWidth,
                max: Constants.maxSplitViewWidth
            )
            .toolbar(removing: .sidebarToggle)
        } detail: {
            if let selectedSpellID,
               let spell = spells.first(where: { $0.id == selectedSpellID }) {
                spellDetail(spell)
                    .id(spell.id)
            } else {
                createSpellButton
            }
        }
        .navigationSplitViewStyle(.prominentDetail)
        .navigationTitle(viewModel.navigationTitle(selectedID: selectedSpellID, in: spells))
        .onChange(of: columnVisibility) { _, newValue in
            if newValue != .all {
                columnVisibility = .all
            }
        }
        .onAppear {
            if selectedSpellID == nil {
                selectedSpellID = spells.first?.id
            }
        }
    }
}

extension SpellsLibraryView {
    private var searchField: some View {
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
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private func levelHeader(_ level: Int) -> some View {
        HStack {
            if level != 0 {
                Text("Rank ")
                Spacer()
                Icons.spellRank(level, filled: true)
                    .foregroundStyle(.secondary)
            } else {
                Text("Cantrips")
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .padding(.bottom, 5)
    }

    private func spellRow(_ spell: Spell) -> some View {
        HStack {
            Button {
                selectedSpellID = spell.id
            } label: {
                HStack {
                    Text(spell.name)
                        .lineLimit(1)
                    Spacer()
                    if spell.isFocusSpell {
                        Icons.focusSpell
                            .foregroundStyle(.secondary)
                    }
                    Icons.spellRank(spell.level)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button {
                viewModel.deleteSpell(spell, using: modelContext)
                if selectedSpellID == spell.id {
                    selectedSpellID = nil
                }
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .opacity(hoveredSpellID == spell.id ? 1 : 0)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            selectedSpellID == spell.id
                ? Color.accentColor.opacity(0.25)
                : (hoveredSpellID == spell.id ? Color.secondary.opacity(0.15) : Color.clear)
        )
        .onHover { hovering in
            hoveredSpellID = hovering ? spell.id : nil
        }
    }

    var addSpellRow: some View {
        Button {
            let newSpell = viewModel.addSpell(using: modelContext)
            selectedSpellID = newSpell.id
        } label: {
            HStack {
                Spacer()
                Icons.add
                Spacer()
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    var createSpellButton: some View {
        Button {
            let newSpell = viewModel.addSpell(using: modelContext)
            selectedSpellID = newSpell.id
        } label: {
            VStack(spacing: 8) {
                Icons.addCircle
                    .font(.largeTitle)
                Text("Create a new spell")
            }
        }
        .buttonStyle(.plain)
    }

    private func aonIDBinding(for spell: Spell) -> Binding<String> {
        Binding(
            get: { spell.aonID.map(String.init) ?? "" },
            set: { newValue in spell.aonID = Int(newValue.trimmingCharacters(in: .whitespaces)) }
        )
    }

    private func spellDetail(_ spell: Spell) -> some View {
        @Bindable var spell = spell
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SelectAllTextField("Spell name", text: $spell.name)
                    .font(.title)
                    .fontDesign(.serif)
                    .fontWeight(.bold)
                    .textFieldStyle(.plain)
                if let warning = viewModel.duplicateNameWarning(for: spell, in: spells) {
                    Text(warning)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                HStack {
                    Text("Level")
                        .fontWeight(.semibold)
                    SelectAllIntField(value: $spell.level, formatter: formatter)
                        .frame(width: 40)
                    Toggle("Focus Spell", isOn: $spell.isFocusSpell)
                        .padding(.leading)
                }
                HStack {
                    Text("Speed")
                        .fontWeight(.semibold)
                    Picker("Speed", selection: $spell.speed) {
                        ForEach(CombatAction.speedValues, id: \.self) { speed in
                            Text(CombatAction.displayText(for: speed) + " " + CombatAction.speedSymbol(for: speed)).tag(speed)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 180)
                }
                HStack {
                    Text("Range")
                        .fontWeight(.semibold)
                    SelectAllTextField("e.g. 30 feet", text: $spell.range)
                    Text("Area")
                        .fontWeight(.semibold)
                    SelectAllTextField("e.g. 15-foot cone", text: $spell.area)
                }
                HStack {
                    Text("Traditions")
                        .fontWeight(.semibold)
                    ForEach(SpellTradition.allCases) { tradition in
                        traditionToggle(tradition, on: spell)
                    }
                }
                Divider()
                Text("Description")
                    .font(.headline)
                TextEditor(text: $spell.details)
                    .frame(minHeight: 200)
                Divider()
                HStack {
                    Text("Archive of Nethys ID")
                        .fontWeight(.semibold)
                    SelectAllTextField("e.g. 1261", text: aonIDBinding(for: spell))
                        .frame(width: 80)
                    if let aonURL = spell.aonURL {
                        Link("View on Archive of Nethys", destination: aonURL)
                    }
                }
                if let warning = viewModel.duplicateAonIDWarning(for: spell, in: spells) {
                    Text(warning)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .padding()
        }
    }

    private func traditionToggle(_ tradition: SpellTradition, on spell: Spell) -> some View {
        let isSelected = spell.traditions.contains(tradition)
        return Button {
            viewModel.toggleTradition(tradition, on: spell)
        } label: {
            Text(tradition.rawValue)
                .padding(4)
                .background(isSelected ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.15))
                .cornerRadius(5)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Spell.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    container.mainContext.insert(Spell(
        name: "Ancient Dust", id: nil, level: 3, isFocusSpell: false,
        details: "You call on ancient dust to fill the air with disease and rot.",
        aonID: 1261, traditions: [.primal, .divine]))
    container.mainContext.insert(Spell(
        name: "Cinder Gaze", id: nil, level: 0, isFocusSpell: true,
        details: "Your eyes glow like burning coals.", traditions: [.arcane]))
    return SpellsLibraryView()
        .modelContainer(container)
}
