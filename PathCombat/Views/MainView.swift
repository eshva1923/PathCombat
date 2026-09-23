//
//  MainView.swift
//  PathCombat
//
//  Created by Federico Brandani on 19/09/2026.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @State private var selectedSection: AppSection = .combatTracker

    var body: some View {
        Group {
            switch selectedSection {
            case .combatTracker:
                CombatTrackerView()
            case .entitiesLibrary:
                EntitiesLibraryView()
            case .rulesAndConditions:
                RulesAndConditionsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Section", selection: $selectedSection) {
                    ForEach(AppSection.allCases) { section in
                        Label(section.rawValue, systemImage: section.systemImage)
                            .tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 420)
            }
        }
    }
}

#Preview {
    MainView()
        .modelContainer(for: Encounter.self, inMemory: true)
}
