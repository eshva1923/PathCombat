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

    @State private var selectedEntityID: UUID?
    @State private var searchText = ""

    private var availableEntities: [CombatEntity] {
        libraryEntities
            .filter { $0.matchesSearch(searchText) }
            .sorted { $0.level > $1.level }
    }

    private var selectedEntity: CombatEntity? {
        guard let selectedEntityID else { return nil }
        return availableEntities.first(where: { $0.id == selectedEntityID })
    }

    var body: some View {
        PickerSheet(
            title: "Load Entity",
            items: availableEntities,
            noun: "entities",
            searchText: $searchText,
            addButtonTitle: "Add to Encounter",
            isAddDisabled: selectedEntity.map { !isAddable($0) } ?? true,
            onAdd: {
                if let selectedEntity {
                    onAdd(selectedEntity)
                }
            },
            row: { entity in entityRow(entity) },
            footer: { EmptyView() }
        )
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
