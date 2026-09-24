import SwiftUI
import SwiftData

struct EncounterView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allConditions: [Condition]
    @Bindable var encounter: Encounter
    @State private var viewModel: EncounterViewModel
    @State private var isShowingEntityPicker = false

    init(encounter: Encounter) {
        self.encounter = encounter
        self._viewModel = State(initialValue: EncounterViewModel(encounter: encounter))
    }

    var body: some View {
        ScrollViewReader { proxy in
            HSplitView {
                VStack(spacing: 0) {
                    topRow
                        .padding()
                    Divider()
                    ScrollView {
                        VStack {
                            ForEach(encounter.combatEntities) { entity in
                                VStack {
                                    CombatEntityView(combatEntity: entity)
                                    
                                    Button {
                                        viewModel.deleteEntity(entity)
                                    } label: {
                                        HStack {
                                            Text("Remove this entity")
                                            Image(systemName: "trash")
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 8)
                                    }
                                    .padding(.vertical)
                                }
                                .padding(4)
                                .background(entity.isDead ? Color.black.opacity(0.3) : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.secondary, lineWidth: entity.id == encounter.actingEntity ? 2 : 0)
                                )
                                .id(entity.id)
                                Divider().padding()
                            }
                            addEntityRow
                        }
                        .padding()
                    }
                    .frame(minHeight: 60)
                    Divider()
                    HStack {
                        Spacer()
                        Text("Added on:")
                            .italic()
                        Text(viewModel.dateAdded)
                            .italic()
                    }
                    .padding()
                }
                .frame(minWidth: 300, maxHeight: .infinity)
                initiativeTracker(proxy: proxy)
                    .frame(minWidth: 160, idealWidth: 160, maxWidth: 400, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: encounter.actingEntity) { _, newValue in
                guard let newValue else { return }
                withAnimation {
                    proxy.scrollTo(newValue, anchor: .top)
                }
            }
        }
        .sheet(isPresented: $isShowingEntityPicker) {
            EntityPickerSheet(isAddable: { viewModel.canAdd($0) }, countInEncounter: { viewModel.addedCount(for: $0) }) { template in
                viewModel.addEntity(from: template)
            }
        }
    }
}

extension EncounterView {
    func initiativeTracker(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Initiative")
                    .font(.headline)
                    .fontDesign(.serif)

                Spacer()
                Button {
                    viewModel.resetEncounter()
                } label: {
                    HStack {
                        Text("Reset")
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .padding(6)
                }
                .disabled(!viewModel.hasStartedCombat)
                Button {
                    if viewModel.needsNPCInitiativeRoll {
                        viewModel.rollInitiativeForNPCs()
                    } else {
                        viewModel.advanceInitiative()
                    }
                } label: {
                    HStack {
                        Text(viewModel.advanceInitiativeButtonText)
                        Image(systemName: "play.fill")
                            .foregroundStyle(viewModel.advanceButtonColor)
                    }
                    .padding(6)
                }
                .disabled(viewModel.isAdvanceButtonDisabled)
                .help(viewModel.advanceButtonHelpText)
            }.padding()
            if encounter.combatEntities.isEmpty {
                Text("No entities added")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                List(viewModel.sortedByInitiative) { entity in
                    initiativeRow(entity, proxy: proxy)
                        .buttonStyle(.plain)
                        .listRowBackground(viewModel.rowBackground(for: entity))
                }
                .listStyle(.plain)
            }
        }
    }

    private func initiativeRow(_ entity: EncounterCombatEntity, proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading) {
            Button {
                withAnimation {
                    proxy.scrollTo(entity.id, anchor: .top)
                }
            } label: {
                initiativeRowHeader(entity)
            }
            if !entity.affectingConditions.isEmpty {
                HStack {
                    ForEach(entity.affectingConditions) { applied in
                        ConditionTag(
                            text: viewModel.conditionTagText(applied, allConditions: allConditions),
                            description: viewModel.conditionDescription(for: applied, allConditions: allConditions),
                            color: .orange)
                    }
                }
            }
        }
    }

    private func initiativeRowHeader(_ entity: EncounterCombatEntity) -> some View {
        HStack {
            if let roleIcon = viewModel.roleIcon(for: entity) {
                Image(systemName: roleIcon)
            }
            Text(entity.name)
                .lineLimit(1)
            if let roleText = viewModel.roleBadgeText(for: entity) {
                LabelTag(text: roleText, color: .roleBadgeColor(for: entity.role), imageName: nil, hoverEffect: false, hoverColor: nil)
            }
            if !entity.affectingConditions.isEmpty {
                Image(systemName: "figure.walk.triangle.fill")
                    .foregroundStyle(.orange)
            }
            if entity.isDead {
                Image(systemName: "figure.teen")
                    .frame(width: 16, height: 16)
                    .rotationEffect(.degrees(90))
                    .foregroundStyle(.red)
            }
            Spacer()
            initiativeRowStats(entity)
        }
    }

    private func initiativeRowStats(_ entity: EncounterCombatEntity) -> some View {
        HStack {
            VStack {
                Image(systemName: "figure.run")
                Text("\(entity.currentIni)")
                    .fontWeight(.bold)
                    .foregroundStyle(entity.currentIni == 0 ? .red : .primary)
            }
            VStack {
                Image(systemName: "heart.fill")
                Text("\(entity.hp)")
                    .fontWeight(.bold)
            }
            VStack {
                Image(systemName: "bandage.fill")
                Text("\(entity.wounds)")
                    .fontWeight(.bold)
                    .foregroundStyle(viewModel.woundSeverityColor(for: entity))
            }
        }
    }

    var addEntityRow: some View {
        Button {
            isShowingEntityPicker = true
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "plus.app")
                Text("Load entity")
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    
    var topRow: some View {
        HStack {
            TextField("Encounter name", text: $encounter.name)
            Text("Difficulty: ")
            LabelTag(text: encounter.calculateDifficulty().rawValue,
                color: .blue, imageName: nil, hoverEffect: false, hoverColor: nil)
            Button {
                encounter.completed.toggle()
            } label: {
                Text("Encounter done")
            }
            .background(encounter.completed ? .red : .clear)

        }
    }
}

#Preview {
    let entities = [
        CombatEntity(name: "Eaudrick Vallemar",
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
                     dc: 21).copyForEncounter()
    ]
    let encounter = Encounter.init(
        name: "test encounter",
        id: nil,
        date: nil,
        completed: nil,
        combatEntities: entities)
    EncounterView(encounter: encounter)
}

#Preview("Ready / Started") {
    let ready = CombatEntity(
        name: "Ready Guy", id: nil, tags: [], level: 1, iniMod: 5, currentIni: 12,
        hp: 20, wounds: nil, currentConditions: nil, ac: 15, fortST: 5, refST: 5, willST: 5, dc: 15).copyForEncounter()
    let readyEncounter = Encounter(name: "Ready", id: nil, date: nil, completed: nil, combatEntities: [ready])

    let started = CombatEntity(
        name: "Started Guy", id: nil, tags: [], level: 1, iniMod: 5, currentIni: 12,
        hp: 20, wounds: nil, currentConditions: nil, ac: 15, fortST: 5, refST: 5, willST: 5, dc: 15).copyForEncounter()
    let startedEncounter = Encounter(
        name: "Started", id: nil, date: nil, completed: nil, combatEntities: [started],
        currentInitiative: 12, elapsedCombatRounds: 0, actingEntity: started.id)

    return VStack {
        EncounterView(encounter: readyEncounter)
        Divider()
        EncounterView(encounter: startedEncounter)
    }
    .frame(width: 900, height: 800)
}
