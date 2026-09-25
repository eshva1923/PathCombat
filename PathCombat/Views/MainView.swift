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
            case .spellsLibrary:
                SpellsLibraryView()
            case .rulesAndConditions:
                ConditionsLibraryView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(selectedSection.rawValue)
        .focusEffectDisabled()
        .toolbar {
            ToolbarItemGroup(
                placement: .principal,
                content: {
                    ForEach(AppSection.allCases) { section in
                        sectionButton(section)
                    }
                }
            )
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
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(selectedSection == section ? Color.accentColor.opacity(0.3) : Color.clear)
            )
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
    }
}

#Preview {
    MainView()
}
