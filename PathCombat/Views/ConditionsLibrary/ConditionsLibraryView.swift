//
//  ConditionsLibraryView.swift
//  PathCombat
//
//  Created by Federico Brandani on 23/09/2026.
//

import SwiftUI
import SwiftData

struct ConditionsLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var conditions: [Condition]
    @State private var viewModel = ConditionsLibraryViewModel()
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var hoveredConditionID: UUID?
    @State private var selectedConditionID: UUID?
    @State private var searchText = ""

    private enum Constants {
        static let minSplitViewWidth = 180.0
        static let idealSplitViewWidth = 200.0
        static let maxSplitViewWidth = 220.0
    }

    private var filteredConditions: [Condition] {
        conditions.filter { $0.matchesSearch(searchText) }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            VStack(spacing: 0) {
                searchField
                Divider()
                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        ForEach(filteredConditions) { condition in
                            conditionRow(condition)
                            Divider()
                        }
                        addConditionRow
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
            if let selectedConditionID,
               let condition = conditions.first(where: { $0.id == selectedConditionID }) {
                conditionDetail(condition)
                    .id(condition.id)
            } else {
                createConditionButton
            }
        }
        .navigationSplitViewStyle(.prominentDetail)
        .navigationTitle(viewModel.navigationTitle(selectedID: selectedConditionID, in: conditions))
        .onChange(of: columnVisibility) { _, newValue in
            if newValue != .all {
                columnVisibility = .all
            }
        }
        .onAppear {
            if selectedConditionID == nil {
                selectedConditionID = conditions.first?.id
            }
        }
    }
}

extension ConditionsLibraryView {
    private var searchField: some View {
        HStack {
            Icons.search.foregroundStyle(.secondary)
            SelectAllTextField(text: $searchText)
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

    private func conditionRow(_ condition: Condition) -> some View {
        HStack {
            Button {
                selectedConditionID = condition.id
            } label: {
                Text(condition.name)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button {
                viewModel.deleteCondition(condition, using: modelContext)
                if selectedConditionID == condition.id {
                    selectedConditionID = nil
                }
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .opacity(hoveredConditionID == condition.id ? 1 : 0)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            selectedConditionID == condition.id
                ? Color.accentColor.opacity(0.25)
                : (hoveredConditionID == condition.id ? Color.secondary.opacity(0.15) : Color.clear)
        )
        .onHover { hovering in
            hoveredConditionID = hovering ? condition.id : nil
        }
    }

    var addConditionRow: some View {
        Button {
            let newCondition = viewModel.addCondition(using: modelContext)
            selectedConditionID = newCondition.id
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

    var createConditionButton: some View {
        Button {
            let newCondition = viewModel.addCondition(using: modelContext)
            selectedConditionID = newCondition.id
        } label: {
            VStack(spacing: 8) {
                Icons.addCircle
                    .font(.largeTitle)
                Text("Create a new condition")
            }
        }
        .buttonStyle(.plain)
    }

    private func damageBinding(for condition: Condition) -> Binding<String> {
        Binding(
            get: { viewModel.damageText(for: condition) },
            set: { newValue in viewModel.setDamage(condition, to: newValue) }
        )
    }

    private func conditionDetail(_ condition: Condition) -> some View {
        @Bindable var condition = condition
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SelectAllTextField("Condition name", text: $condition.name)
                    .font(.title)
                    .fontDesign(.serif)
                    .fontWeight(.bold)
                    .textFieldStyle(.plain)
                Divider()
                Text("Description")
                    .font(.headline)
                TextEditor(text: $condition.details)
                    .frame(minHeight: 200)
                Divider()
                Toggle("Persistent Damage", isOn: $condition.isPersistent)
                    .font(.headline)
                if condition.isPersistent {
                    SelectAllTextField("Default damage, e.g. 1d6 Acid (optional — can be set per application instead)", text: damageBinding(for: condition))
                }
            }
            .padding()
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Condition.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    container.mainContext.insert(Condition(
        name: "Prone",
        id: nil,
        description: "You're lying on the ground. You're flat-footed and must spend 1 action to stand up."))
    container.mainContext.insert(Condition(
        name: "Frightened",
        id: nil,
        description: "You're gripped by fear and take a penalty to checks and DCs equal to the condition's value."))
    return ConditionsLibraryView()
        .modelContainer(container)
}
