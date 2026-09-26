import SwiftUI
import SwiftData

struct SpellsLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var spells: [Spell]
    @State private var viewModel = SpellsLibraryViewModel()
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedSpellID: UUID?
    @State private var searchText = ""
    @State private var expandedSection: SpellLibrarySection?

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

    private var groupedSpells: [(section: SpellLibrarySection, spells: [Spell])] {
        viewModel.groupedSpells(spells.filter { $0.matchesSearch(searchText) })
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            VStack(spacing: 0) {
                searchField
                Divider()
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                        ForEach(groupedSpells, id: \.section) { group in
                            Section {
                                if !searchText.isEmpty || expandedSection == group.section {
                                    ForEach(group.spells) { spell in
                                        spellRow(spell)
                                        Divider()
                                    }
                                }
                            } header: {
                                sectionHeader(group.section)
                            }
                        }
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
                SpellDetailView(spell: spell, allSpells: spells, viewModel: viewModel, formatter: formatter)
                    .id(spell.id)
            } else {
                CreateNewItemButton(title: "Create a new spell") {
                    let newSpell = viewModel.addSpell(using: modelContext)
                    selectedSpellID = newSpell.id
                }
            }
        }
        .navigationSplitViewStyle(.prominentDetail)
        .navigationTitle(viewModel.navigationTitle(selectedID: selectedSpellID, in: spells))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    let newSpell = viewModel.addSpell(using: modelContext)
                    selectedSpellID = newSpell.id
                    expandedSection = newSpell.isFocusSpell ? .focus : (newSpell.level == 0 ? .cantrip : .rank(newSpell.level))
                } label: {
                    Icons.add
                }
            }
        }
        .onChange(of: columnVisibility) { _, newValue in
            if newValue != .all {
                columnVisibility = .all
            }
        }
        .onAppear {
            if selectedSpellID == nil {
                let cantripGroup = groupedSpells.first { $0.section == .cantrip }
                selectedSpellID = cantripGroup?.spells.first?.id ?? groupedSpells.first?.spells.first?.id
            }
            if expandedSection == nil {
                let selected = spells.first(where: { $0.id == selectedSpellID })
                if let selected {
                    expandedSection = selected.isFocusSpell ? .focus : (selected.level == 0 ? .cantrip : .rank(selected.level))
                } else {
                    expandedSection = groupedSpells.first?.section
                }
            }
        }
    }
}

extension SpellsLibraryView {
    private var searchField: some View {
        SearchField(text: $searchText)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
    }

    private func sectionHeader(_ section: SpellLibrarySection) -> some View {
        CollapsibleSectionHeader(
            isExpanded: expandedSection == section,
            onToggle: { expandedSection = expandedSection == section ? nil : section }
        ) {
            switch section {
            case .cantrip:
                Text("Cantrips")
                Spacer()
            case .rank(let level):
                Text("Rank ")
                Spacer()
                Icons.spellRank(level, filled: true)
                    .foregroundStyle(.secondary)
            case .focus:
                Text("Focus")
                Spacer()
                Icons.focusSpell
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func spellRow(_ spell: Spell) -> some View {
        LibraryRow(
            isSelected: selectedSpellID == spell.id,
            onSelect: { selectedSpellID = spell.id },
            onDelete: {
                viewModel.deleteSpell(spell, using: modelContext)
                if selectedSpellID == spell.id {
                    selectedSpellID = nil
                }
            }
        ) {
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
        }
    }
}

private struct SpellDetailView: View {
    @Bindable var spell: Spell
    let allSpells: [Spell]
    let viewModel: SpellsLibraryViewModel
    let formatter: NumberFormatter
    @State private var tagsBuffer: String

    init(spell: Spell, allSpells: [Spell], viewModel: SpellsLibraryViewModel, formatter: NumberFormatter) {
        self.spell = spell
        self.allSpells = allSpells
        self.viewModel = viewModel
        self.formatter = formatter
        self._tagsBuffer = State(initialValue: spell.tags.joined(separator: ", "))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SelectAllTextField("Spell name", text: $spell.name)
                    .font(.title)
                    .fontDesign(.serif)
                    .fontWeight(.bold)
                    .textFieldStyle(.plain)
                if let warning = viewModel.duplicateNameWarning(for: spell, in: allSpells) {
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
                        traditionToggle(tradition)
                    }
                }
                HStack {
                    Image(systemName: "tag")
                    ForEach(spell.tags, id: \.self) { tag in
                        LabelTag(text: tag, color: .accentColor, imageName: nil, hoverEffect: false, hoverColor: nil)
                    }
                }
                HStack {
                    Image(systemName: "tag")
                    TextField("Tags (comma separated)", text: $tagsBuffer)
                        .onChange(of: tagsBuffer) { _, newValue in
                            viewModel.updateTags(on: spell, from: newValue)
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
                    SelectAllTextField("e.g. 1261", text: aonIDBinding)
                        .frame(width: 80)
                    if let aonURL = spell.aonURL {
                        Link("View on Archive of Nethys", destination: aonURL)
                    }
                }
                if let warning = viewModel.duplicateAonIDWarning(for: spell, in: allSpells) {
                    Text(warning)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .padding()
        }
    }

    private var aonIDBinding: Binding<String> {
        Binding(
            get: { spell.aonID.map(String.init) ?? "" },
            set: { newValue in spell.aonID = Int(newValue.trimmingCharacters(in: .whitespaces)) }
        )
    }

    private func traditionToggle(_ tradition: SpellTradition) -> some View {
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
