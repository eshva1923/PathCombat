//
//  CombatEntityView.swift
//  PathCombat
//
//  Created by Federico Brandani on 21/09/2026.
//

import SwiftUI
import SwiftData

struct CombatEntityView<Entity: CombatEntityStats>: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allConditions: [Condition]
    @Bindable var combatEntity: Entity
    @State private var viewModel: CombatEntityViewModel<Entity>
    @State private var tagsText: String
    @State private var isShowingConditionPicker = false
    let isTemplate: Bool

    let formatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            return formatter
    }()

    init(combatEntity: Entity, isTemplate: Bool = false) {
        self.combatEntity = combatEntity
        self.isTemplate = isTemplate
        self._viewModel = State(initialValue: CombatEntityViewModel(combatEntity: combatEntity))
        self._tagsText = State(initialValue: combatEntity.tags.joined(separator: ", "))
    }
    
    var body: some View {
        Group {
            HStack{
                TextField(text: $combatEntity.name) {
                    Image(systemName: "figure.stand")
                }.font(.title)
                    .fontDesign(.serif)
                    .fontWeight(.bold)
                Image(systemName: "figure.stand")
                levelTag
                if !combatEntity.affectingConditions.isEmpty {
                    Image(systemName: "figure.walk.triangle.fill")
                        .foregroundStyle(.orange)
                }
                if combatEntity.isDead {
                    deadIcon
                }
            }
            .padding(.vertical)
            roleField
            if isTemplate {
                tagsField
            } else {
                HStack{
                    ForEach (combatEntity.tags, id: \.self) {tag in
                        LabelTag(text: tag, color: .accentColor, imageName: nil, hoverEffect: false, hoverColor: nil)
                    }
                }
            }
            StatRow
                HStack {
                    if !isTemplate {
                        initiativeSection
                    }
                    hpSection
                    
                }.padding(.horizontal, 10)
            if !isTemplate {
                conditionsSection
            }
        }
        .padding(.horizontal)
    }
    
    var levelTag: some View {
        HStack(spacing: 4) {
            Text("Level")
            TextField(value: $combatEntity.level, formatter: formatter) {
                EmptyView()
            }
            .frame(width: 30)
        }
        .padding(3)
        .background(Color.brown)
        .cornerRadius(5)
    }

    var roleField: some View {
        HStack {
            Image(systemName: "person.fill.badge.plus")
            Picker("Role", selection: $combatEntity.role) {
                ForEach(CombatRole.allCases) { role in
                    Text(role.displayName).tag(role)
                }
            }
            .labelsHidden()
        }
        .padding(.horizontal, 10)
    }

    var tagsField: some View {
        HStack {
            Image(systemName: "tag")
            TextField("Tags (comma separated)", text: $tagsText)
                .onChange(of: tagsText) { _, newValue in
                    viewModel.updateTags(from: newValue)
                }
        }
        .padding(.horizontal, 10)
    }
            
            
    
    var initiativeSection: some View {
        HStack {
            Image(systemName: "figure.run")
            Text("Initiative")
                .fontWeight(.bold)
            TextField(value: $combatEntity.currentIni,
                      formatter: formatter) {
                Image(systemName: "figure.run")
            }.fontWeight(.bold)
            Button {
                viewModel.rollInitiative()
            } label: {
                HStack {
                    Text("Roll Initiative")
                    Image(systemName: "figure.run.circle")
                }
            }.frame(maxWidth: .infinity)
        }
    }
    
    var hpSection: some View {
            HStack {
                Image(systemName: "heart.fill")
                Text("HP")
                    .fontWeight(.bold)
                TextField(value: $combatEntity.hp,
                          formatter: formatter) {
                    Image(systemName: "heart.fill")
                }.fontWeight(.bold)
                if !isTemplate {
                    Spacer()
                    Image(systemName: "bandage.fill")
                    Text("Wounds")
                        .fontWeight(.medium)
                    TextField(value: $combatEntity.wounds,
                              formatter: formatter) {
                        Image(systemName: "bandage.fill")
                    }.fontWeight(.medium)
                }
            }

    }

    var deadIcon: some View {
        Image(systemName: "figure.teen")
            .frame(width: 16, height: 16)
            .rotationEffect(.degrees(90))
            .foregroundStyle(.red)
    }

    var conditionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Conditions")
                    .fontWeight(.bold)
                Spacer()
                Button {
                    isShowingConditionPicker = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            if combatEntity.affectingConditions.isEmpty {
                Text("No conditions applied")
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 8) {
                    ForEach(combatEntity.affectingConditions) { applied in
                        ConditionTag(
                            text: viewModel.conditionTagText(for: applied, allConditions: allConditions),
                            description: viewModel.conditionDescription(for: applied, allConditions: allConditions),
                            color: .orange,
                            value: valueBinding(for: applied),
                            onDelete: { viewModel.removeCondition(applied) })
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .sheet(isPresented: $isShowingConditionPicker) {
            ConditionPickerSheet(excludedConditionIDs: Set(combatEntity.affectingConditions.map(\.conditionID))) { condition, value in
                viewModel.addCondition(condition, value: value)
            }
        }
    }

    private func valueBinding(for applied: AppliedCondition) -> Binding<String> {
        Binding(
            get: { viewModel.conditionValueText(for: applied) },
            set: { newValue in viewModel.setConditionValue(applied, to: newValue) }
        )
    }
    
    var StatRow: some View {
        Group {
            HStack {
            LabelStat(
                text: "Fortitude",
                value: $combatEntity.fortST,
                imageName: "figure.boxing",
                hoverEffect: true,
                hoverColor: nil,
                isEditable: isTemplate)
            LabelStat(
                text: "Reflexes",
                value: $combatEntity.refST,
                imageName: "figure.fall",
                hoverEffect: true,
                hoverColor: nil,
                isEditable: isTemplate)
            LabelStat(
                text: "Will",
                value: $combatEntity.willST,
                imageName: "brain.fill",
                hoverEffect: true,
                hoverColor: nil,
                isEditable: isTemplate)
            LabelStat(
                text: "Perception",
                value: $combatEntity.iniMod,
                imageName: "bolt",
                hoverEffect: true,
                hoverColor: Color.orange,
                isEditable: isTemplate)

        }
            HStack {
                LabelStat(
                    text: "AC",
                    value: $combatEntity.ac,
                    imageName: "shield.lefthalf.filled",
                    hoverEffect: false,
                    hoverColor: nil,
                    isEditable: isTemplate)
                LabelStat(
                    text: "DC",
                    value: $combatEntity.dc,
                    imageName: "dot.scope",
                    hoverEffect: false,
                    hoverColor: nil,
                    isEditable: isTemplate)
            }
        }
    }
}


#Preview {
    //var entities: [CombatEntity] = []
    let entity = CombatEntity(
        name: "Eaudrick Vallemar",
        id: nil,
        tags: ["Human", "Boss", "Tactician"],
        level: 8,
        iniMod: 15,
        currentIni: nil,
        hp: 200,
        wounds: nil,
        currentConditions: nil,
        ac: 25,
        fortST: 12,
        refST: 8,
        willST: 21,
        dc: 21)

    CombatEntityView(combatEntity: entity)
}
