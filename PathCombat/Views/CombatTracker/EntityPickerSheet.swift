//
//  EntityPickerSheet.swift
//  PathCombat
//
//  Created by Federico Brandani on 23/09/2026.
//

import SwiftUI
import SwiftData

struct EntityPickerSheet: View {
    @Query private var libraryEntities: [CombatEntity]
    let isAddable: (CombatEntity) -> Bool
    let countInEncounter: (CombatEntity) -> Int
    let onAdd: (CombatEntity) -> Void

    @State private var viewModel = EntitiesLibraryViewModel()
    @State private var selectedEntityID: UUID?
    @State private var searchText = ""
    @State private var activeRoles: Set<CombatRole> = Set(CombatRole.allCases)
    @State private var expandedRole: CombatRole?

    private var populatedRoles: [CombatRole] {
        viewModel.groupedEntities(libraryEntities).map(\.role)
    }

    private var filteredEntities: [CombatEntity] {
        libraryEntities.filter { $0.matchesSearch(searchText) && activeRoles.contains($0.role) }
    }

    private var groupedEntities: [(role: CombatRole, entities: [CombatEntity])] {
        viewModel.groupedEntities(filteredEntities)
    }

    private var selectedEntity: CombatEntity? {
        guard let selectedEntityID else { return nil }
        return filteredEntities.first(where: { $0.id == selectedEntityID })
    }

    private var emptyMessage: String {
        guard !activeRoles.isEmpty else { return "No roles selected" }
        return pickerSheetEmptyMessage(noun: "entities", searchText: searchText)
    }

    var body: some View {
        PickerSheet(
            title: "Load Entity",
            searchText: $searchText,
            isEmpty: filteredEntities.isEmpty,
            emptyMessage: emptyMessage,
            addButtonTitle: "Add to Encounter",
            isAddDisabled: selectedEntity.map { !isAddable($0) } ?? true,
            onAdd: {
                if let selectedEntity {
                    onAdd(selectedEntity)
                }
            },
            accessory: { roleToggleRow },
            listContent: {
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
                            roleSectionHeader(group.role)
                        }
                    }
                }
            },
            footer: { EmptyView() }
        )
        .onAppear {
            if expandedRole == nil {
                expandedRole = populatedRoles.contains(.pc) ? .pc : populatedRoles.first
            }
        }
    }

    private var roleToggleRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(populatedRoles) { role in
                    roleToggle(role)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    private func roleToggle(_ role: CombatRole) -> some View {
        let isOn = activeRoles.contains(role)
        return Button {
            if isOn {
                activeRoles.remove(role)
            } else {
                activeRoles.insert(role)
            }
        } label: {
            HStack(spacing: 4) {
                if let icon = role.icon {
                    Image(systemName: icon)
                }
                Text(role.displayName)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isOn ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.15))
            .cornerRadius(5)
        }
        .buttonStyle(.plain)
    }

    private func roleSectionHeader(_ role: CombatRole) -> some View {
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
        let addable = isAddable(entity)
        return LibraryRow(isSelected: selectedEntityID == entity.id, onSelect: { selectedEntityID = entity.id }) {
            VStack(alignment: .leading) {
                HStack {
                    if let roleIcon = entity.role.icon {
                        Image(systemName: roleIcon)
                    }
                    Text(entity.name)
                        .fontWeight(.semibold)
                    if entity.role != .pc && entity.role != .boss {
                        LabelTag(text: "In encounter: \(countInEncounter(entity))", color: .secondary.opacity(0.25))
                    }
                    Spacer()
                    LabelTag(text: "Level \(entity.level)", color: .brown)
                }
                HStack {
                    ForEach(entity.tags, id: \.self) { tag in
                        LabelTag(text: tag, color: .accentColor)
                    }
                }
            }
        }
        .disabled(!addable)
        .opacity(addable ? 1 : 0.4)
        .help(addable ? "" : "Only one \(entity.name) can be added to an encounter")
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Encounter.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    container.mainContext.insert(CombatEntity(
        name: "Eaudrick Vallemar", id: nil, tags: ["Human", "Boss"], level: 8, iniMod: 15,
        currentIni: nil, hp: 200, wounds: nil,
        ac: 25, fortST: 12, refST: 8, willST: 21, dc: 21))
    container.mainContext.insert(CombatEntity(
        name: "Goblin Scout", id: nil, tags: ["Goblin"], level: 1, iniMod: 4,
        currentIni: nil, hp: 12, wounds: nil,
        ac: 14, fortST: 2, refST: 4, willST: 1, dc: 12))
    return EntityPickerSheet(isAddable: { _ in true }, countInEncounter: { _ in 0 }, onAdd: { _ in })
        .modelContainer(container)
}
