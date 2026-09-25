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
    @State private var hoveredEncounterID: UUID?
    @State private var selectedEncounterID: UUID?
    @State private var searchText = ""

    private enum Constants {
        static let minSplitViewWidth = 180.0
        static let idealSplitViewWidth = 200.0
        static let maxSplitViewWidth = 220.0
    }

    private var filteredEncounters: [Encounter] {
        encounters.filter { $0.matchesSearch(searchText) }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            VStack(spacing: 0) {
                searchField
                Divider()
                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        ForEach(filteredEncounters) { encounter in
                            encounterRow(encounter)
                            Divider()
                        }
                        addEncounterRow.padding(4)
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
            } else {
                createEncounterButton.padding()
            }
        }
        .navigationSplitViewStyle(.prominentDetail)
        .navigationTitle(viewModel.navigationTitle(selectedID: selectedEncounterID, in: encounters))
        .onChange(of: columnVisibility) { _, newValue in
            if newValue != .all {
                columnVisibility = .all
            }
        }
        .onAppear {
            if selectedEncounterID == nil {
                selectedEncounterID = encounters.first?.id
            }
        }
    }
}

extension CombatTrackerView {
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

    private func encounterRow(_ encounter: Encounter) -> some View {
        HStack {
            Button {
                selectedEncounterID = encounter.id
            } label: {
                HStack {
                    Text(encounter.name)
                        .lineLimit(1)
                    Spacer()
                    Text("\(encounter.session)")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button {
                viewModel.deleteEncounter(encounter, using: modelContext)
                if selectedEncounterID == encounter.id {
                    selectedEncounterID = nil
                }
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .opacity(hoveredEncounterID == encounter.id ? 1 : 0)
        }
        .padding(6)
        .background(
            selectedEncounterID == encounter.id
                ? Color.accentColor.opacity(0.25)
                : (hoveredEncounterID == encounter.id ? Color.secondary.opacity(0.15) : Color.clear)
        )
        .onHover { hovering in
            hoveredEncounterID = hovering ? encounter.id : nil
        }
    }

    var addEncounterRow: some View {
        Button {
            let newEncounter = viewModel.addEncounter(using: modelContext)
            selectedEncounterID = newEncounter.id
        } label: {
            HStack {
                Spacer()
                Icons.add
                Spacer()
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
    }

    var createEncounterButton: some View {
        Button {
            let newEncounter = viewModel.addEncounter(using: modelContext)
            selectedEncounterID = newEncounter.id
        } label: {
            VStack(spacing: 8) {
                Icons.addCircle
                    .font(.largeTitle)
                Text("Create a new encounter")
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Encounter.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    container.mainContext.insert(Encounter(name: "Goblin Ambush", id: nil, date: nil, completed: nil, combatEntities: nil))
    container.mainContext.insert(Encounter(name: "Dragon's Lair", id: nil, date: nil, completed: nil, combatEntities: nil))
    container.mainContext.insert(Encounter(name: "Bandit Camp", id: nil, date: nil, completed: nil, combatEntities: nil))
    return CombatTrackerView()
        .modelContainer(container)
}
