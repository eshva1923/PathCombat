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
        VStack(spacing: 0) {
            Picker("Section", selection: $selectedSection) {
                ForEach(AppSection.allCases) { section in
                    Label(section.rawValue, systemImage: section.systemImage)
                        .tag(section)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding()

            Divider()

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
        }
    }
}

#Preview {
    MainView()
        .modelContainer(for: Encounter.self, inMemory: true)
}
