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
    @Query private var allSpells: [Spell]
    @Bindable var combatEntity: Entity
    @State private var viewModel: CombatEntityViewModel<Entity>
    @State private var tagsText: String
    @State private var speedBuffer: String
    @State private var isShowingConditionPicker = false
    @State private var isShowingSpellPicker = false
    @State private var spellPickerRank = 0
    @State private var isShowingFocusSpellPicker = false
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
        self._speedBuffer = State(initialValue: combatEntity.speed.map { $0.displayText }.joined(separator: ", "))
    }
    
    var body: some View {
        Group {
            HStack{
                Icons.character
                SelectAllTextField(text: $combatEntity.name)
                    .font(.title)
                    .fontDesign(.serif)
                    .fontWeight(.bold)
                levelTag
                roleField
                if isTemplate {
                    Button {
                        viewModel.syncToEncounters(using: modelContext)
                    } label: {
                        Label("Sync to Encounters", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
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
                statSection
                    HStack {
                        if !isTemplate {
                            initiativeSection
                        }
                        Spacer()
                        hpSection

                    }.padding(.horizontal, 10)
                if !isTemplate {
                    conditionsSection
                }
                if combatEntity.role != .pc {
                    actionsSection
                    spellsSection
                }
            }
        }
        .padding(.horizontal)
    }
    
    var levelTag: some View {
        HStack(spacing: 4) {
            Text("Level")
            SelectAllIntField(value: $combatEntity.level, formatter: formatter)
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

    var speedField: some View {
        HStack {
            Icons.speed
            Text("Speed")
                .fontWeight(.semibold)
            if isTemplate {
                TextField("Speed (e.g. 30, 45 swimming)", text: $speedBuffer)
                    .onChange(of: speedBuffer) { _, newValue in
                        viewModel.setSpeed(from: newValue)
                    }
            } else {
                ForEach(combatEntity.speed, id: \.self) { speed in
                    LabelTag(text: speed.displayText, color: .accentColor, imageName: nil, hoverEffect: false, hoverColor: nil)
                }
            }
        }
    }
    
    var sizeField: some View {
        HStack {
            Icons.size
            Text("Size")
                .fontWeight(.semibold)
            if isTemplate {
                Picker("Size", selection: $combatEntity.size) {
                    ForEach(CreatureSize.allCases) { size in
                        Text(size.rawValue).tag(size)
                    }
                }
                .labelsHidden()
                .frame(width: 110)
            } else {
                Text(combatEntity.size.rawValue)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    var hpSection: some View {
            Group {
                Icons.hp
                Text("HP")
                    .fontWeight(.bold)
                SelectAllIntField(value: $combatEntity.hp, formatter: formatter)
                    .fontWeight(.bold)
                if !isTemplate {
                    Spacer()
                    Icons.wounds
                    Text("Wounds")
                        .fontWeight(.medium)
                    SelectAllIntField(value: $combatEntity.wounds, formatter: formatter)
                        .fontWeight(.medium)
                }
            }

    }
            
            
    
    var initiativeSection: some View {
        HStack {
            Icons.initiative
            Text("Initiative")
                .fontWeight(.bold)
            SelectAllIntField(value: $combatEntity.currentIni, formatter: formatter)
                .fontWeight(.bold)
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
                    SelectAllTextField("Name", text: binding.name)
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
                    SelectAllIntField(value: binding.toHit, formatter: formatter)
                        .frame(width: 40)
                    SelectAllTextField("Damage (e.g. 2d6+4)", text: binding.damage)
                } else {
                    Text("+\(action.toHit) vs \(action.target.displayName)")
                        .foregroundStyle(.secondary)
                    Text(action.damage)
                        .fontWeight(.semibold)
                }
            }
            if isTemplate {
                SelectAllTextField("Description", text: binding.desc)
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

    var spellsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Spells")
                    .fontWeight(.bold)
                Spacer()
                if isTemplate {
                    Button {
                        viewModel.toggleSpellcasting()
                    } label: {
                        Text(combatEntity.spellcasting == nil ? "Enable Spellcasting" : "Disable Spellcasting")
                    }
                }
            }
            if combatEntity.spellcasting == nil {
                Text("Not a spellcaster")
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    focusPointsRow
                    spellRankRow(rank: 0)
                    ForEach(1...10, id: \.self) { rank in
                        spellRankRow(rank: rank)
                    }
                    focusSpellsRow
                }
            }
        }
        .padding(10)
        .background(Color.elementBackground.opacity(0.25))
        .cornerRadius(8)
        .padding(.horizontal, 10)
        .sheet(isPresented: $isShowingSpellPicker) {
            SpellPickerSheet(isFocusSpell: false, level: spellPickerRank, excludedSpellIDs: Set(combatEntity.spellcasting?.knownSpellIDs ?? [])) { spell in
                viewModel.addSpell(spell)
            }
        }
        .sheet(isPresented: $isShowingFocusSpellPicker) {
            SpellPickerSheet(isFocusSpell: true, excludedSpellIDs: Set(combatEntity.spellcasting?.focusSpellIDs ?? [])) { spell in
                viewModel.addFocusSpell(spell)
            }
        }
    }

    private var focusPointsRow: some View {
        HStack {
            Text("Focus Points")
                .fontWeight(.semibold)
                .frame(width: 90, alignment: .leading)
            if isTemplate {
                Picker("Total", selection: focusPointsTotalBinding) {
                    ForEach([0, 1, 2, 3], id: \.self) { value in
                        Text("\(value)").tag(value)
                    }
                }
                .labelsHidden()
                .frame(width: 70)
            } else {
                pipsStepper(value: focusPointsSpentBinding, total: viewModel.focusPointsTotal())
            }
        }
    }

    private func pips(spent: Int, total: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<total, id: \.self) { index in
                Image(systemName: index < spent ? "circle.fill" : "circle")
            }
        }
    }

    private func pipsStepper(value: Binding<Int>, total: Int) -> some View {
        HStack(spacing: 4) {
            Button {
                value.wrappedValue = max(0, value.wrappedValue - 1)
            } label: {
                Image(systemName: "minus.circle")
            }
            .buttonStyle(.plain)
            .disabled(value.wrappedValue <= 0)

            pips(spent: value.wrappedValue, total: total)

            Button {
                value.wrappedValue = min(total, value.wrappedValue + 1)
            } label: {
                Image(systemName: "plus.circle")
            }
            .buttonStyle(.plain)
            .disabled(value.wrappedValue >= total)
        }
    }

    @ViewBuilder
    private func spellRankRow(rank: Int) -> some View {
        let spellsForRank = viewModel.knownSpells(rank: rank, allSpells: allSpells)
        if isTemplate {
            HStack(alignment: .top) {
                Icons.spellRank(rank)
                    .frame(width: 30, alignment: .leading)
                if rank > 0 {
                    Text("Slots")
                    SelectAllIntField(value: availableSlotsBinding(rank: rank), formatter: formatter)
                        .frame(width: 30)
                }
                spellTags(spellsForRank, onRemove: { viewModel.removeSpell($0) })
                if rank == 0 || viewModel.availableSlots(rank: rank) > 0 {
                    Button {
                        spellPickerRank = rank
                        isShowingSpellPicker = true
                    } label: {
                        Icons.add
                    }
                    .buttonStyle(.plain)
                }
            }
        } else if viewModel.availableSlots(rank: rank) > 0 || !spellsForRank.isEmpty {
            HStack(alignment: .top) {
                Icons.spellRank(rank)
                    .frame(width: 30, alignment: .leading)
                if rank > 0 {
                    pipsStepper(value: spentSlotsBinding(rank: rank), total: viewModel.availableSlots(rank: rank))
                }
                spellTags(spellsForRank)
            }
        }
    }

    private func spellTags(_ spells: [Spell], onRemove: ((Spell) -> Void)? = nil) -> some View {
        HStack {
            ForEach(spells) { spell in
                SpellTag(spell: spell, onDelete: onRemove.map { remove in { remove(spell) } })
            }
        }
    }

    private var focusSpellsRow: some View {
        HStack(alignment: .top) {
            Text("Focus Spells")
                .fontWeight(.semibold)
                .frame(width: 90, alignment: .leading)
            spellTags(viewModel.focusSpells(allSpells: allSpells), onRemove: isTemplate ? { viewModel.removeFocusSpell($0) } : nil)
            if isTemplate && viewModel.focusPointsTotal() > 0 {
                Button {
                    isShowingFocusSpellPicker = true
                } label: {
                    Icons.add
                }
            }
        }
    }

    private var focusPointsTotalBinding: Binding<Int> {
        Binding(
            get: { viewModel.focusPointsTotal() },
            set: { newValue in viewModel.setFocusPointsTotal(newValue) }
        )
    }

    private var focusPointsSpentBinding: Binding<Int> {
        Binding(
            get: { viewModel.focusPointsSpent() },
            set: { newValue in viewModel.setFocusPointsSpent(newValue) }
        )
    }

    private func availableSlotsBinding(rank: Int) -> Binding<Int> {
        Binding(
            get: { viewModel.availableSlots(rank: rank) },
            set: { newValue in viewModel.setAvailableSlots(rank: rank, to: newValue) }
        )
    }

    private func spentSlotsBinding(rank: Int) -> Binding<Int> {
        Binding(
            get: { viewModel.spentSlots(rank: rank) },
            set: { newValue in viewModel.setSpentSlots(rank: rank, to: newValue) }
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
    var statSection: some View {
        Group {
            VStack {
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
                    Spacer()
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
                        hoverEffect: true,
                        hoverColor: nil,
                        isEditable: isTemplate,
                        image: Icons.ac)
                    LabelStat(
                        text: "DC",
                        value: $combatEntity.dc,
                        hoverEffect: true,
                        hoverColor: nil,
                        isEditable: isTemplate,
                        image: Icons.dc)
                    Spacer()
                    speedField
                        .frame(maxWidth: 200)
                    sizeField
                }
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
