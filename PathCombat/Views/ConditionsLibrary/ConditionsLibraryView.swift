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

    private enum Constants {
        static let minSplitViewWidth = 180.0
        static let idealSplitViewWidth = 200.0
        static let maxSplitViewWidth = 220.0
    }

    private var navigationTitleText: String {
        if let selectedConditionID,
           let condition = conditions.first(where: { $0.id == selectedConditionID }) {
            return "\(AppSection.rulesAndConditions.rawValue) - \(condition.name)"
        }
        return AppSection.rulesAndConditions.rawValue
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    ForEach(conditions) { condition in
                        conditionRow(condition)
                        Divider()
                    }
                    addConditionRow
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
        .navigationTitle(navigationTitleText)
        .onChange(of: columnVisibility) { _, newValue in
            if newValue != .all {
                columnVisibility = .all
            }
        }
    }
}

extension ConditionsLibraryView {
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
            viewModel.addCondition(using: modelContext)
        } label: {
            HStack {
                Spacer()
                Image(systemName: "plus")
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
                Image(systemName: "plus.circle")
                    .font(.largeTitle)
                Text("Create a new condition")
            }
        }
        .buttonStyle(.plain)
    }

    private func conditionDetail(_ condition: Condition) -> some View {
        @Bindable var condition = condition
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Condition name", text: $condition.name)
                    .font(.title)
                    .fontDesign(.serif)
                    .fontWeight(.bold)
                    .textFieldStyle(.plain)
                Divider()
                Text("Description")
                    .font(.headline)
                TextEditor(text: $condition.details)
                    .frame(minHeight: 200)
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
