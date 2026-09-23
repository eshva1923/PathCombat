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
    let onAdd: (CombatEntity) -> Void

    @State private var selectedEntityID: UUID?
    @State private var hoveredEntityID: UUID?

    private var availableEntities: [CombatEntity] {
        libraryEntities.sorted { $0.level > $1.level }
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Load Entity")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            Divider()
            if availableEntities.isEmpty {
                Spacer()
                Text("No entities available in the library")
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
                    if let selectedEntityID,
                       let entity = availableEntities.first(where: { $0.id == selectedEntityID }) {
                        onAdd(entity)
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedEntityID == nil)
            }
            .padding()
        }
        .frame(minWidth: 440, minHeight: 380)
    }

    private func entityRow(_ entity: CombatEntity) -> some View {
        Button {
            selectedEntityID = entity.id
        } label: {
            HStack {
                Text(entity.name)
                    .fontWeight(.semibold)
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
        .background(
            selectedEntityID == entity.id
                ? Color.accentColor.opacity(0.25)
                : (hoveredEntityID == entity.id ? Color.secondary.opacity(0.15) : Color.clear)
        )
        .onHover { hovering in
            hoveredEntityID = hovering ? entity.id : nil
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
    return EntityPickerSheet(onAdd: { _ in })
        .modelContainer(container)
}
