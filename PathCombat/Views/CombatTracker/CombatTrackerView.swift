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

    private enum Constants {
        static let minSplitViewWidth = 180.0
        static let idealSplitViewWidth = 200.0
        static let maxSplitViewWidth = 220.0
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    ForEach(encounters) { encounter in
                        encounterRow(encounter)
                        Divider()
                    }
                    addEncounterRow
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
                createEncounterButton
            }
        }
        .navigationSplitViewStyle(.prominentDetail)
        .navigationTitle(viewModel.navigationTitle(selectedID: selectedEncounterID, in: encounters))
        .onChange(of: columnVisibility) { _, newValue in
            if newValue != .all {
                columnVisibility = .all
            }
        }
    }
}

extension CombatTrackerView {
    private func encounterRow(_ encounter: Encounter) -> some View {
        HStack {
            Button {
                selectedEncounterID = encounter.id
            } label: {
                Text(encounter.name)
                    .lineLimit(1)
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
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
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
            viewModel.addEncounter(using: modelContext)
        } label: {
            HStack {
                Spacer()
                Image(systemName: "plus")
                Spacer()
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    var createEncounterButton: some View {
        Button {
            let newEncounter = viewModel.addEncounter(using: modelContext)
            selectedEncounterID = newEncounter.id
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "plus.circle")
                    .font(.largeTitle)
                Text("Create a new encounter")
            }
        }
        .buttonStyle(.plain)
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
