//
//  ConditionPickerSheet.swift
//  PathCombat
//
//  Created by Federico Brandani on 23/09/2026.
//

import SwiftUI
import SwiftData

struct ConditionPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var libraryConditions: [Condition]
    let excludedConditionIDs: Set<UUID>
    let onAdd: (Condition, Int?, String?) -> Void

    @State private var selectedConditionID: UUID?
    @State private var valueText: String = ""
    @State private var damageText: String = ""
    @State private var searchText = ""

    private var availableConditions: [Condition] {
        libraryConditions
            .filter { !excludedConditionIDs.contains($0.id) }
            .filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.name < $1.name }
    }

    private var selectedCondition: Condition? {
        guard let selectedConditionID else { return nil }
        return availableConditions.first(where: { $0.id == selectedConditionID })
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Add Condition")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            SearchField(text: $searchText)
                .padding(.horizontal)
                .padding(.bottom, 8)
            Divider()
            if availableConditions.isEmpty {
                Spacer()
                Text(searchText.isEmpty ? "No conditions available in the library" : "No conditions match \"\(searchText)\"")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(availableConditions) { condition in
                            conditionRow(condition)
                            Divider()
                        }
                    }
                }
            }
            Divider()
            if selectedCondition?.isPersistent == true {
                HStack {
                    Text("Damage")
                    SelectAllTextField("e.g. 1d6 Acid", text: $damageText)
                }
                .padding()
            } else {
                HStack {
                    Text("Value (optional)")
                    SelectAllTextField("e.g. 2", text: $valueText)
                        .frame(width: 60)
                }
                .padding()
            }
            Divider()
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
                Button("Add") {
                    if let selectedConditionID,
                       let condition = availableConditions.first(where: { $0.id == selectedConditionID }) {
                        onAdd(condition, Int(valueText), condition.resolvedDamage(from: damageText))
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedConditionID == nil)
            }
            .padding()
        }
        .frame(minWidth: 420, minHeight: 380)
        .onChange(of: selectedConditionID) { _, _ in
            damageText = selectedCondition?.damage ?? ""
        }
    }

    private func conditionRow(_ condition: Condition) -> some View {
        LibraryRow(isSelected: selectedConditionID == condition.id, onSelect: { selectedConditionID = condition.id }) {
            Text(condition.name)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Condition.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    container.mainContext.insert(Condition(name: "Prone", id: nil, description: "Flat-footed, lying down."))
    container.mainContext.insert(Condition(name: "Frightened", id: nil, description: "Penalty to checks and DCs."))
    return ConditionPickerSheet(excludedConditionIDs: [], onAdd: { _, _, _ in })
        .modelContainer(container)
}
