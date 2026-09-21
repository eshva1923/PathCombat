//
//  MainView.swift
//  PathCombat
//
//  Created by Federico Brandani on 19/09/2026.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var encounters: [Encounter]

    private enum Constants {
        static let minSplitViewWidth = 180.0
        static let idealSplitViewWidth = 200.0
        static let maxSplitViewWidth = 220.0
        static let addEncounterText = "Add new encounter"
        static let addEncounterSystemImageName = "plus"
    }
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(encounters) { encounter in
                    NavigationLink {
                        EncounterView(encounter: encounter)
                    } label: {
                        Text(encounter.name)
                    }
                }
                .onDelete(perform: deleteEncounter)
            }
            .navigationSplitViewColumnWidth(
                min: Constants.minSplitViewWidth,
                ideal: Constants.idealSplitViewWidth,
                max: Constants.maxSplitViewWidth
            )
            .toolbar {
                ToolbarItem {
                    Button(action: addEncounter) {
                        Label(
                            Constants.addEncounterText,
                            systemImage: Constants.addEncounterSystemImageName
                        )
                    }
                }
            }
        } detail: {
            Text("Select an encounter")
        }
    }
}

extension MainView {
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
    
    private func deleteEncounter(_ offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(encounters[index])
            }
        }
    }
}

#Preview {
    MainView()
        .modelContainer(for: Encounter.self, inMemory: true)
}
