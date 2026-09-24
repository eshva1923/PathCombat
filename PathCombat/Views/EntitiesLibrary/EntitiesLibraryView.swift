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
    @State private var hoveredEntityID: UUID?
    @State private var selectedEntityID: UUID?
    @State private var searchText = ""

    private enum Constants {
        static let minSplitViewWidth = 180.0
        static let idealSplitViewWidth = 200.0
        static let maxSplitViewWidth = 220.0
    }

    private var filteredEntities: [CombatEntity] {
        entities.filter { $0.matchesSearch(searchText) }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            VStack(spacing: 0) {
                searchField
                Divider()
                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        ForEach(filteredEntities) { entity in
                            entityRow(entity)
                            Divider()
                        }
                        addEntityRow
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
                createEntityButton
            }
        }
        .navigationSplitViewStyle(.prominentDetail)
        .navigationTitle(viewModel.navigationTitle(selectedID: selectedEntityID, in: entities))
        .onChange(of: columnVisibility) { _, newValue in
            if newValue != .all {
                columnVisibility = .all
            }
        }
        .onAppear {
            if selectedEntityID == nil {
                selectedEntityID = entities.first?.id
            }
        }
    }
}

extension EntitiesLibraryView {
    private var searchField: some View {
        HStack {
            Icons.search.foregroundStyle(.secondary)
            TextField("Search by name, level, tag, or role", text: $searchText)
                .textFieldStyle(.plain)
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
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private func entityRow(_ entity: CombatEntity) -> some View {
        HStack {
            Button {
                selectedEntityID = entity.id
            } label: {
                HStack {
                    if let roleIcon = entity.role.icon {
                        Image(systemName: roleIcon)
                    }
                    Text(entity.name)
                        .lineLimit(1)
                    Spacer()
                    Text("Level \(entity.level)")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button {
                viewModel.deleteEntity(entity, using: modelContext)
                if selectedEntityID == entity.id {
                    selectedEntityID = nil
                }
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .opacity(hoveredEntityID == entity.id ? 1 : 0)
            .help("Delete entity")
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            selectedEntityID == entity.id
                ? Color.accentColor.opacity(0.25)
                : (hoveredEntityID == entity.id ? Color.secondary.opacity(0.15) : Color.clear)
        )
        .onHover { hovering in
            hoveredEntityID = hovering ? entity.id : nil
        }
    }

    var addEntityRow: some View {
        Button {
            let newEntity = viewModel.addEntity(using: modelContext)
            selectedEntityID = newEntity.id
        } label: {
            HStack {
                Spacer()
                Icons.add
                Spacer()
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    var createEntityButton: some View {
        Button {
            let newEntity = viewModel.addEntity(using: modelContext)
            selectedEntityID = newEntity.id
        } label: {
            VStack(spacing: 8) {
                Icons.addCircle
                    .font(.largeTitle)
                Text("Create a new entity")
            }
        }
        .buttonStyle(.plain)
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
