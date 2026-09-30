//
//  ConditionPickerSheet.swift
//  PathCombat
//
//  Created by Federico Brandani on 23/09/2026.
//

import SwiftUI
import SwiftData

struct ConditionPickerSheet: View {
    @Query private var libraryConditions: [Condition]
    let excludedConditionIDs: Set<UUID>
    let onAdd: (Condition, Int?, String?) -> Void

    @State private var selectedConditionID: UUID?
    @State private var valueText: String = ""
    @State private var damageText: String = ""
    @State private var searchText = ""

    private var availableConditions: [Condition] {
        libraryConditions
            .filter { !excludedConditionIDs.contains($0.id) && $0.matchesSearch(searchText) }
            .sorted { $0.name < $1.name }
    }

    private var selectedCondition: Condition? {
        guard let selectedConditionID else { return nil }
        return availableConditions.first(where: { $0.id == selectedConditionID })
    }

    var body: some View {
        PickerSheet(
            title: "Add Condition",
            items: availableConditions,
            noun: "conditions",
            searchText: $searchText,
            isAddDisabled: selectedConditionID == nil,
            onAdd: {
                if let selectedConditionID,
                   let condition = availableConditions.first(where: { $0.id == selectedConditionID }) {
                    onAdd(condition, Int(valueText), condition.resolvedDamage(from: damageText))
                }
            },
            row: { condition in
                LibraryRow(isSelected: selectedConditionID == condition.id, onSelect: { selectedConditionID = condition.id }) {
                    Text(condition.name)
                        .fontWeight(.semibold)
                }
            },
            footer: {
                Group {
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
                }
            }
        )
        .onChange(of: selectedConditionID) { _, _ in
            damageText = selectedCondition?.damage ?? ""
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
