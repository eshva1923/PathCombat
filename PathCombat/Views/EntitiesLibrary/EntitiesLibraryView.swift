//
//  EntitiesLibraryView.swift
//  PathCombat
//
//  Created by Federico Brandani on 23/09/2026.
//

import SwiftUI
import SwiftData

struct EntitiesLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var entities: [CombatEntity]
    @State private var viewModel = EntitiesLibraryViewModel()
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedEntityID: UUID?
    @State private var searchText = ""
    @State private var expandedRole: CombatRole?

    private enum Constants {
        static let minSplitViewWidth = 180.0
        static let idealSplitViewWidth = 200.0
        static let maxSplitViewWidth = 220.0
    }

    private var filteredEntities: [CombatEntity] {
        entities.filter { $0.matchesSearch(searchText) }
    }

    private var groupedEntities: [(role: CombatRole, entities: [CombatEntity])] {
        viewModel.groupedEntities(filteredEntities)
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            VStack(spacing: 0) {
                searchField
                Divider()
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                        ForEach(groupedEntities, id: \.role) { group in
                            Section {
                                if !searchText.isEmpty || expandedRole == group.role {
                                    ForEach(group.entities) { entity in
                                        entityRow(entity)
                                        Divider()
                                    }
                                }
                            } header: {
                                roleHeader(group.role)
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
            if let selectedEntityID,
               let entity = entities.first(where: { $0.id == selectedEntityID }) {
                ScrollView {
                    CombatEntityView(combatEntity: entity, isTemplate: true)
                        .padding(.top)
                        .id(entity.id)
                }
            } else {
                CreateNewItemButton(title: "Create a new entity") {
                    let newEntity = viewModel.addEntity(using: modelContext)
                    selectedEntityID = newEntity.id
                }
            }
        }
        .navigationSplitViewStyle(.prominentDetail)
        .navigationTitle(viewModel.navigationTitle(selectedID: selectedEntityID, in: entities))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    let newEntity = viewModel.addEntity(using: modelContext)
                    selectedEntityID = newEntity.id
                    expandedRole = newEntity.role
                } label: {
                    HStack {
                        Text("Add a new entity")
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
            if selectedEntityID == nil {
                selectedEntityID = groupedEntities.first?.entities.first?.id
            }
            if expandedRole == nil {
                let selected = entities.first(where: { $0.id == selectedEntityID })
                expandedRole = selected?.role ?? groupedEntities.first?.role
            }
        }
    }
}

extension EntitiesLibraryView {
    private var searchField: some View {
        SearchField(text: $searchText)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
    }

    private func roleHeader(_ role: CombatRole) -> some View {
        CollapsibleSectionHeader(
            isExpanded: expandedRole == role,
            onToggle: { expandedRole = expandedRole == role ? nil : role }
        ) {
            if let icon = role.icon {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
            }
            Text(role.displayName)
            Spacer()
        }
    }

    private func entityRow(_ entity: CombatEntity) -> some View {
        LibraryRow(
            isSelected: selectedEntityID == entity.id,
            onSelect: { selectedEntityID = entity.id },
            onDelete: {
                viewModel.deleteEntity(entity, using: modelContext)
                if selectedEntityID == entity.id {
                    selectedEntityID = nil
                }
            },
            deleteHelpText: "Delete entity"
        ) {
            HStack {
                Text(entity.name)
                    .lineLimit(1)
                Spacer()
                Text("Level \(entity.level)")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Encounter.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    container.mainContext.insert(CombatEntity(
        name: "Eaudrick Vallemar", id: nil, tags: ["Human", "Boss"], level: 8, iniMod: 15,
        currentIni: nil, hp: 200, wounds: nil, currentConditions: nil,
        ac: 25, fortST: 12, refST: 8, willST: 21, dc: 21))
    container.mainContext.insert(CombatEntity(
        name: "Goblin Scout", id: nil, tags: ["Goblin"], level: 1, iniMod: 4,
        currentIni: nil, hp: 12, wounds: nil, currentConditions: nil,
        ac: 14, fortST: 2, refST: 4, willST: 1, dc: 12))
    return EntitiesLibraryView()
        .modelContainer(container)
}
