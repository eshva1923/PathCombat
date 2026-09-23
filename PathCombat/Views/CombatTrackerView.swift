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
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var hoveredEncounterID: UUID?

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
            Text("Select an encounter")
        }
        .navigationSplitViewStyle(.prominentDetail)
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
            NavigationLink {
                EncounterView(encounter: encounter)
            } label: {
                Text(encounter.name)
                    .lineLimit(1)
            }
            .buttonStyle(.plain)
            Spacer()
            Button {
                deleteEncounter(encounter)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .opacity(hoveredEncounterID == encounter.id ? 1 : 0)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(hoveredEncounterID == encounter.id ? Color.secondary.opacity(0.15) : Color.clear)
        .onHover { hovering in
            hoveredEncounterID = hovering ? encounter.id : nil
        }
    }

    var addEncounterRow: some View {
        Button(action: addEncounter) {
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

    private func addEncounter() {
        withAnimation {
            let newItem = Encounter(
                name: "New Encounter",
                id: nil,
                date: nil,
                completed: nil,
                combatEntities: nil)
            modelContext.insert(newItem)
        }
    }
    
    private func deleteEncounter(_ encounter: Encounter) {
        withAnimation {
            modelContext.delete(encounter)
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
