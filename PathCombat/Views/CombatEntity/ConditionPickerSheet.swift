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
    @State private var hoveredConditionID: UUID?
    @State private var valueText: String = ""
    @State private var damageText: String = ""

    private var availableConditions: [Condition] {
        libraryConditions
            .filter { !excludedConditionIDs.contains($0.id) }
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
            Divider()
            if availableConditions.isEmpty {
                Spacer()
                Text("No conditions available in the library")
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
                    TextField("e.g. 1d6 Acid", text: $damageText)
                }
                .padding()
            } else {
                HStack {
                    Text("Value (optional)")
                    TextField("e.g. 2", text: $valueText)
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
        Button {
            selectedConditionID = condition.id
        } label: {
            Text(condition.name)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            selectedConditionID == condition.id
                ? Color.accentColor.opacity(0.25)
                : (hoveredConditionID == condition.id ? Color.secondary.opacity(0.15) : Color.clear)
        )
        .onHover { hovering in
            hoveredConditionID = hovering ? condition.id : nil
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
