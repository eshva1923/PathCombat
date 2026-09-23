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
        .navigationTitle(selectedSection.rawValue)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 4) {
                    ForEach(AppSection.allCases) { section in
                        sectionButton(section)
                    }
                }
            }
        }
    }

    private func sectionButton(_ section: AppSection) -> some View {
        Button {
            selectedSection = section
        } label: {
            VStack(spacing: 2) {
                Image(systemName: section.systemImage)
                    .font(.system(size: 15))
                Text(section.rawValue)
                    .font(.caption2)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .frame(minWidth: 90)
            .background(
                selectedSection == section
                    ? Color.accentColor.opacity(0.25)
                    : Color.clear
            )
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainView()
        .modelContainer(for: Encounter.self, inMemory: true)
}
