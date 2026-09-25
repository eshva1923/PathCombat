//
//  EntityPickerSheet.swift
//  PathCombat
//
//  Created by Federico Brandani on 23/09/2026.
//

import SwiftUI
import SwiftData

struct EntityPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var libraryEntities: [CombatEntity]
    let isAddable: (CombatEntity) -> Bool
    let countInEncounter: (CombatEntity) -> Int
    let onAdd: (CombatEntity) -> Void

    @State private var selectedEntityID: UUID?
    @State private var hoveredEntityID: UUID?
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
        VStack(spacing: 0) {
            Text("Load Entity")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            HStack {
                Icons.search.foregroundStyle(.secondary)
                TextField("", text: $searchText)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            Divider()
            if availableEntities.isEmpty {
                Spacer()
                Text(searchText.isEmpty ? "No entities available in the library" : "No entities match \"\(searchText)\"")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(availableEntities) { entity in
                            entityRow(entity)
                            Divider()
                        }
                    }
                }
            }
            Divider()
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
                Button("Add to Encounter") {
                    if let selectedEntity {
                        onAdd(selectedEntity)
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedEntity.map { !isAddable($0) } ?? true)
            }
            .padding()
        }
        .frame(minWidth: 440, minHeight: 380)
    }

    private func entityRow(_ entity: CombatEntity) -> some View {
        let addable = isAddable(entity)
        return Button {
            selectedEntityID = entity.id
        } label: {
            HStack {
                if let roleIcon = entity.role.icon {
                    Image(systemName: roleIcon)
                }
                Text(entity.name)
                    .fontWeight(.semibold)
                if entity.role != .pc && entity.role != .boss {
                    LabelTag(text: "In encounter: \(countInEncounter(entity))", color: .secondary.opacity(0.25), imageName: nil, hoverEffect: false, hoverColor: nil)
                }
                Spacer()
                HStack {
                    ForEach(entity.tags, id: \.self) { tag in
                        LabelTag(text: tag, color: .accentColor, imageName: nil, hoverEffect: false, hoverColor: nil)
                    }
                    LabelTag(text: "Level \(entity.level)", color: .brown, imageName: nil, hoverEffect: false, hoverColor: nil)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .disabled(!addable)
        .opacity(addable ? 1 : 0.4)
        .background(
            selectedEntityID == entity.id
                ? Color.accentColor.opacity(0.25)
                : (hoveredEntityID == entity.id ? Color.secondary.opacity(0.15) : Color.clear)
        )
        .onHover { hovering in
            hoveredEntityID = hovering ? entity.id : nil
        }
        .help(addable ? "" : "Only one \(entity.name) can be added to an encounter")
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
    return EntityPickerSheet(isAddable: { _ in true }, countInEncounter: { _ in 0 }, onAdd: { _ in })
        .modelContainer(container)
}
