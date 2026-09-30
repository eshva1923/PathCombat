//
//  RulesLibraryView.swift
//  PathCombat
//
//  Created by Federico Brandani on 23/09/2026.
//

import SwiftUI
import SwiftData

struct RulesLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var conditions: [Condition]
    @Query private var ruleActions: [RuleAction]
    @State private var viewModel = RulesLibraryViewModel()
    @State private var selectedItemID: UUID?
    @State private var searchText = ""
    @State private var expandedSection: RulesLibrarySection?

    private var filteredConditions: [Condition] {
        viewModel.sortedConditions(conditions.filter { $0.matchesSearch(searchText) })
    }

    private var filteredActions: [RuleAction] {
        ruleActions.filter { $0.matchesSearch(searchText) }
    }

    private var actionsOnly: [RuleAction] {
        viewModel.sortedActions(filteredActions, kind: .action)
    }

    private var activitiesOnly: [RuleAction] {
        viewModel.sortedActions(filteredActions, kind: .activity)
    }

    private var selectedCondition: Condition? {
        conditions.first(where: { $0.id == selectedItemID })
    }

    private var selectedAction: RuleAction? {
        ruleActions.first(where: { $0.id == selectedItemID })
    }

    var body: some View {
        LibrarySplitView(searchText: $searchText) {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                Section {
                    if !searchText.isEmpty || expandedSection == .conditions {
                        ForEach(filteredConditions) { condition in
                            conditionRow(condition)
                            Divider()
                        }
                    }
                } header: {
                    sectionHeader(.conditions)
                }
                Section {
                    if !searchText.isEmpty || expandedSection == .actions {
                        ForEach(actionsOnly) { action in
                            actionRow(action)
                            Divider()
                        }
                    }
                } header: {
                    sectionHeader(.actions)
                }
                Section {
                    if !searchText.isEmpty || expandedSection == .activities {
                        ForEach(activitiesOnly) { action in
                            actionRow(action)
                            Divider()
                        }
                    }
                } header: {
                    sectionHeader(.activities)
                }
            }
        } detail: {
            if let condition = selectedCondition {
                conditionDetail(condition)
                    .id(condition.id)
            } else if let action = selectedAction {
                RuleActionDetailView(action: action, viewModel: viewModel)
                    .id(action.id)
            } else {
                CreateNewItemButton(title: "Create a new \(newItemLabel)") {
                    addItem(for: expandedSection ?? .conditions)
                }
            }
        }
        .navigationTitle(viewModel.navigationTitle(selectedID: selectedItemID, conditions: conditions, actions: ruleActions))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Condition") { addItem(for: .conditions) }
                    Button("Action") { addItem(for: .actions) }
                    Button("Activity") { addItem(for: .activities) }
                } label: {
                    HStack {
                        Text("Add")
                        Icons.add
                    }
                    .padding(.horizontal)
                }
            }
        }
        .onAppear {
            if selectedItemID == nil {
                selectedItemID = filteredConditions.first?.id
            }
            if expandedSection == nil {
                expandedSection = .conditions
            }
        }
    }

    private var newItemLabel: String {
        switch expandedSection ?? .conditions {
        case .conditions: return "condition"
        case .actions: return "action"
        case .activities: return "activity"
        }
    }

    private func addItem(for section: RulesLibrarySection) {
        switch section {
        case .conditions:
            let newCondition = viewModel.addCondition(using: modelContext)
            selectedItemID = newCondition.id
        case .actions:
            let newAction = viewModel.addAction(kind: .action, using: modelContext)
            selectedItemID = newAction.id
        case .activities:
            let newAction = viewModel.addAction(kind: .activity, using: modelContext)
            selectedItemID = newAction.id
        }
        expandedSection = section
    }
}

extension RulesLibraryView {
    private func sectionHeader(_ section: RulesLibrarySection) -> some View {
        CollapsibleSectionHeader(
            isExpanded: expandedSection == section,
            onToggle: { expandedSection = expandedSection == section ? nil : section }
        ) {
            switch section {
            case .conditions:
                Text("Conditions")
                Spacer()
            case .actions:
                Text("Actions")
                Spacer()
                Icons.action
                    .foregroundStyle(.secondary)
            case .activities:
                Text("Activities")
                Spacer()
                Icons.activity
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func conditionRow(_ condition: Condition) -> some View {
        LibraryRow(
            isSelected: selectedItemID == condition.id,
            onSelect: { selectedItemID = condition.id },
            onDelete: {
                viewModel.deleteCondition(condition, using: modelContext)
                if selectedItemID == condition.id {
                    selectedItemID = nil
                }
            }
        ) {
            Text(condition.name)
                .lineLimit(1)
        }
    }

    private func actionRow(_ action: RuleAction) -> some View {
        LibraryRow(
            isSelected: selectedItemID == action.id,
            onSelect: { selectedItemID = action.id },
            onDelete: {
                viewModel.deleteAction(action, using: modelContext)
                if selectedItemID == action.id {
                    selectedItemID = nil
                }
            }
        ) {
            HStack {
                Text(action.name)
                    .lineLimit(1)
                Spacer()
                if let speed = action.speed {
                    Text(CombatAction.speedSymbol(for: speed))
                        .foregroundStyle(.secondary)
                }
            }
        }
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

private struct RuleActionDetailView: View {
    @Bindable var action: RuleAction
    let viewModel: RulesLibraryViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SelectAllTextField("Action name", text: $action.name)
                    .font(.title)
                    .fontDesign(.serif)
                    .fontWeight(.bold)
                    .textFieldStyle(.plain)
                HStack {
                    Text("Kind")
                        .fontWeight(.semibold)
                    Picker("Kind", selection: $action.kind) {
                        ForEach(RuleActionKind.allCases) { kind in
                            Text(kind.displayName).tag(kind)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                    Text("Cost")
                        .fontWeight(.semibold)
                        .padding(.leading)
                    Picker("Cost", selection: $action.speed) {
                        Text("None").tag(Int?.none)
                        ForEach(CombatAction.speedValues, id: \.self) { speed in
                            Text(CombatAction.displayText(for: speed) + " " + CombatAction.speedSymbol(for: speed)).tag(Int?.some(speed))
                        }
                    }
                    .labelsHidden()
                    .frame(width: 220)
                }
                TagsEditor(tags: action.tags) { viewModel.updateTags(on: action, from: $0) }
                Divider()
                Text("Description")
                    .font(.headline)
                TextEditor(text: $action.details)
                    .frame(minHeight: 200)
                Divider()
                AoNIDField(aonID: $action.aonID, placeholder: "e.g. 88", url: action.aonURL)
            }
            .padding()
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Condition.self, RuleAction.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    container.mainContext.insert(Condition(
        name: "Prone",
        id: nil,
        description: "You're lying on the ground. You're flat-footed and must spend 1 action to stand up."))
    container.mainContext.insert(Condition(
        name: "Frightened",
        id: nil,
        description: "You're gripped by fear and take a penalty to checks and DCs equal to the condition's value."))
    return RulesLibraryView()
        .modelContainer(container)
}
