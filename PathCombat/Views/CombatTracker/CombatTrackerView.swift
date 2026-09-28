//
//  CombatTrackerView.swift
//  PathCombat
//
//  Created by Federico Brandani on 19/09/2026.
//

import SwiftUI
import SwiftData

struct CombatTrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var encounters: [Encounter]
    @State private var viewModel = CombatTrackerViewModel()
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedEncounterID: UUID?
    @State private var searchText = ""
    @State private var expandedSession: Int?

    private enum Constants {
        static let minSplitViewWidth = 180.0
        static let idealSplitViewWidth = 200.0
        static let maxSplitViewWidth = 220.0
    }

    private var filteredEncounters: [Encounter] {
        encounters.filter { $0.matchesSearch(searchText) }
    }

    private var groupedEncounters: [(session: Int, encounters: [Encounter])] {
        viewModel.groupedBySession(filteredEncounters)
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            VStack(spacing: 0) {
                searchField
                Divider()
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                        ForEach(groupedEncounters, id: \.session) { group in
                            Section {
                                if !searchText.isEmpty || expandedSession == group.session {
                                    ForEach(group.encounters) { encounter in
                                        encounterRow(encounter)
                                        Divider()
                                    }
                                }
                            } header: {
                                sessionHeader(group.session)
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
            if let selectedEncounterID,
               let encounter = encounters.first(where: { $0.id == selectedEncounterID }) {
                EncounterView(encounter: encounter)
                    .id(encounter.id)
            } else {
                CreateNewItemButton(title: "Create a new encounter") {
                    let newEncounter = viewModel.addEncounter(using: modelContext)
                    selectedEncounterID = newEncounter.id
                }
                .padding()
            }
        }
        .navigationSplitViewStyle(.prominentDetail)
        .navigationTitle(viewModel.navigationTitle(selectedID: selectedEncounterID, in: encounters))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    let newEncounter = viewModel.addEncounter(using: modelContext)
                    selectedEncounterID = newEncounter.id
                    expandedSession = newEncounter.session
                } label: {
                    HStack {
                        Text("Add a new encounter")
                        Icons.add
                    }
                    .padding(.horizontal)
                }
            }
        }
        .onChange(of: columnVisibility) { _, newValue in
            if newValue != .all {
                columnVisibility = .all
            }
        }
        .onAppear {
            if selectedEncounterID == nil {
                selectedEncounterID = groupedEncounters.first?.encounters.first?.id
            }
            if expandedSession == nil {
                let selected = encounters.first(where: { $0.id == selectedEncounterID })
                expandedSession = selected?.session ?? groupedEncounters.first?.session
            }
        }
    }
}

extension CombatTrackerView {
    private var searchField: some View {
        SearchField(text: $searchText)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
    }

    private func sessionHeader(_ session: Int) -> some View {
        CollapsibleSectionHeader(
            isExpanded: expandedSession == session,
            onToggle: { expandedSession = expandedSession == session ? nil : session }
        ) {
            Text("Session \(session)")
            Spacer()
        }
    }

    private func encounterRow(_ encounter: Encounter) -> some View {
        LibraryRow(
            isSelected: selectedEncounterID == encounter.id,
            onSelect: { selectedEncounterID = encounter.id },
            onDelete: {
                viewModel.deleteEncounter(encounter, using: modelContext)
                if selectedEncounterID == encounter.id {
                    selectedEncounterID = nil
                }
            }
        ) {
            HStack {
                Text(encounter.name)
                    .lineLimit(1)
                Spacer()
                Text("\(encounter.session)")
            }
            .strikethrough(encounter.completed)
            .foregroundStyle(encounter.completed ? .secondary : .primary)
        }
    }

}

#Preview {
    let container = try! ModelContainer(
        for: Encounter.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    container.mainContext.insert(Encounter(name: "Goblin Ambush", id: nil, date: nil, completed: true, combatEntities: nil))
    container.mainContext.insert(Encounter(name: "Dragon's Lair", id: nil, date: nil, completed: nil, combatEntities: nil))
    container.mainContext.insert(Encounter(name: "Bandit Camp", id: nil, date: nil, completed: nil, combatEntities: nil))
    return CombatTrackerView()
        .modelContainer(container)
}
