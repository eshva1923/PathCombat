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
    let isCollapsed: Bool

    let formatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            return formatter
    }()

    init(combatEntity: Entity, isTemplate: Bool = false, isCollapsed: Bool = false) {
        self.combatEntity = combatEntity
        self.isTemplate = isTemplate
        self.isCollapsed = isCollapsed
        self._viewModel = State(initialValue: CombatEntityViewModel(combatEntity: combatEntity))
        self._tagsText = State(initialValue: combatEntity.tags.joined(separator: ", "))
    }
    
    var body: some View {
        Group {
            HStack{
                TextField(text: $combatEntity.name) {
                    Icons.character
                }.font(.title)
                    .fontDesign(.serif)
                    .fontWeight(.bold)
                levelTag
                roleField
                if !combatEntity.affectingConditions.isEmpty {
                    Icons.affectedByConditions.foregroundStyle(.orange)
                }
                if combatEntity.isDead {
                    deadIcon
                }
            }
            .padding(.vertical)

            if !isCollapsed {
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
                actionsSection
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
            Icons.addRole
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
            Icons.initiative
            Text("Initiative")
                .fontWeight(.bold)
            TextField(value: $combatEntity.currentIni,
                      formatter: formatter) {
                Icons.initiative
            }.fontWeight(.bold)
            Button {
                viewModel.rollInitiative()
            } label: {
                HStack {
                    Text("Roll Initiative")
                    Icons.rollInitiative
                }
            }.frame(maxWidth: .infinity)
        }
    }
    
    var hpSection: some View {
            HStack {
                Icons.hp
                Text("HP")
                    .fontWeight(.bold)
                TextField(value: $combatEntity.hp,
                          formatter: formatter) {
                    Icons.hp
                }.fontWeight(.bold)
                if !isTemplate {
                    Spacer()
                    Icons.wounds
                    Text("Wounds")
                        .fontWeight(.medium)
                    TextField(value: $combatEntity.wounds,
                              formatter: formatter) {
                        Icons.wounds
                    }.fontWeight(.medium)
                }
            }

    }

    var deadIcon: some View {
        Icons.dead
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
                    Icons.add
                }
            }
            if combatEntity.affectingConditions.isEmpty {
                Text("No conditions applied")
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 8) {
                    ForEach(viewModel.sortedConditions(combatEntity.affectingConditions, allConditions: allConditions)) { applied in
                        let isPersistentDamage = viewModel.isPersistentDamage(for: applied, allConditions: allConditions)
                        ConditionTag(
                            text: viewModel.conditionTagText(for: applied, allConditions: allConditions),
                            description: viewModel.conditionDescription(for: applied, allConditions: allConditions),
                            color: viewModel.conditionTagColor(for: applied, allConditions: allConditions),
                            isFilled: isPersistentDamage,
                            value: isPersistentDamage ? nil : valueBinding(for: applied),
                            damage: isPersistentDamage ? damageBinding(for: applied) : nil,
                            onDelete: { viewModel.removeCondition(applied) })
                    }
                }
            }
        }
        .padding(10)
        .background(Color.elementBackground.opacity(0.25))
        .cornerRadius(8)
        .padding(.horizontal, 10)
        .sheet(isPresented: $isShowingConditionPicker) {
            ConditionPickerSheet(excludedConditionIDs: viewModel.nonStackableConditionIDs(allConditions: allConditions)) { condition, value, damage in
                viewModel.addCondition(condition, value: value, damage: damage)
            }
        }
    }

    var actionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Actions")
                    .fontWeight(.bold)
                Spacer()
                if isTemplate {
                    Button {
                        viewModel.addAction()
                    } label: {
                        Icons.add
                    }
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                ForEach(combatEntity.actions) { action in
                    actionRow(action)
                }
            }
        }
        .padding(10)
        .background(Color.elementBackground.opacity(0.25))
        .cornerRadius(8)
        .padding(.horizontal, 10)
    }

    private func actionRow(_ action: CombatAction) -> some View {
        let binding = actionBinding(for: action)
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                if isTemplate {
                    TextField("Name", text: binding.name)
                        .fontWeight(.bold)
                } else {
                    Text(action.name)
                        .fontWeight(.bold)
                }
                Spacer()
                if isTemplate {
                    Picker("Speed", selection: binding.speed) {
                        ForEach(CombatAction.speedValues, id: \.self) { speed in
                            Text(CombatAction.displayText(for: speed) + " " + CombatAction.speedSymbol(for: speed)).tag(speed)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 140)
                    Button {
                        viewModel.removeAction(action)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(action.speedSymbol)
                        .foregroundStyle(.secondary)
                }
            }
            HStack {
                if isTemplate {
                    Picker("Target", selection: binding.target) {
                        ForEach(ActionTarget.allCases) { target in
                            Text(target.displayName).tag(target)
                        }
                    }
                    .labelsHidden()
                    Text("To Hit")
                    TextField(value: binding.toHit, formatter: formatter) {
                        EmptyView()
                    }
                    .frame(width: 40)
                    TextField("Damage (e.g. 2d6+4)", text: binding.damage)
                } else {
                    Text("+\(action.toHit) vs \(action.target.displayName)")
                        .foregroundStyle(.secondary)
                    Text(action.damage)
                        .fontWeight(.semibold)
                }
            }
            if isTemplate {
                TextField("Description", text: binding.desc)
                    .font(.caption)
            } else if !action.desc.isEmpty {
                Text(action.desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(6)
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(6)
    }

    private func actionBinding(for action: CombatAction) -> Binding<CombatAction> {
        Binding(
            get: { viewModel.action(withID: action.id) ?? action },
            set: { newValue in viewModel.updateAction(newValue) }
        )
    }

    private func valueBinding(for applied: AppliedCondition) -> Binding<String> {
        Binding(
            get: { viewModel.conditionValueText(for: applied) },
            set: { newValue in viewModel.setConditionValue(applied, to: newValue) }
        )
    }

    private func damageBinding(for applied: AppliedCondition) -> Binding<String> {
        Binding(
            get: { viewModel.conditionDamageText(for: applied) },
            set: { newValue in viewModel.setConditionDamage(applied, to: newValue) }
        )
    }
    
    var StatRow: some View {
        Group {
            HStack {
            LabelStat(
                text: "Fortitude",
                value: $combatEntity.fortST,
                hoverEffect: true,
                hoverColor: nil,
                isEditable: isTemplate,
                image: Icons.fortitude)
            LabelStat(
                text: "Reflexes",
                value: $combatEntity.refST,
                hoverEffect: true,
                hoverColor: nil,
                isEditable: isTemplate,
                image: Icons.reflexes)
            LabelStat(
                text: "Will",
                value: $combatEntity.willST,
                hoverEffect: true,
                hoverColor: nil,
                isEditable: isTemplate,
                image: Icons.will)
            LabelStat(
                text: "Perception",
                value: $combatEntity.iniMod,
                hoverEffect: true,
                hoverColor: Color.orange,
                isEditable: isTemplate,
                image: Icons.perception)

        }
            HStack {
                LabelStat(
                    text: "AC",
                    value: $combatEntity.ac,
                    hoverEffect: false,
                    hoverColor: nil,
                    isEditable: isTemplate,
                    image: Icons.ac)
                LabelStat(
                    text: "DC",
                    value: $combatEntity.dc,
                    hoverEffect: false,
                    hoverColor: nil,
                    isEditable: isTemplate,
                    image: Icons.dc)
            }
        }
    }
}


#Preview {
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
