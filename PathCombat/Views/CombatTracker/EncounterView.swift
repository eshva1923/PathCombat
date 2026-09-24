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
                                    HStack {
                                        Button {
                                            viewModel.deleteEntity(entity)
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                    }
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
        }
        .sheet(isPresented: $isShowingEntityPicker) {
            EntityPickerSheet(isAddable: { viewModel.canAdd($0) }) { template in
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

    private func initiativeRow(_ entity: CombatEntity, proxy: ScrollViewProxy) -> some View {
        Button {
            withAnimation {
                proxy.scrollTo(entity.id, anchor: .top)
            }
        } label: {
            VStack(alignment: .leading) {
                initiativeRowHeader(entity)
                HStack {
                    ForEach(entity.affectingConditions) { applied in
                        LabelTag(
                            text: viewModel.conditionTagText(applied, allConditions: allConditions),
                            color: .orange, imageName: nil, hoverEffect: false, hoverColor: nil)
                    }
                }
            }
        }
    }

    private func initiativeRowHeader(_ entity: CombatEntity) -> some View {
        HStack {
            Text(entity.name)
                .lineLimit(1)
            if let tag = viewModel.uniquePerEncounterTag(for: entity) {
                LabelTag(text: tag, color: .entityTagColor(for: tag), imageName: nil, hoverEffect: false, hoverColor: nil)
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

    private func initiativeRowStats(_ entity: CombatEntity) -> some View {
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
                     dc: 21)
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
        hp: 20, wounds: nil, currentConditions: nil, ac: 15, fortST: 5, refST: 5, willST: 5, dc: 15)
    let readyEncounter = Encounter(name: "Ready", id: nil, date: nil, completed: nil, combatEntities: [ready])

    let started = CombatEntity(
        name: "Started Guy", id: nil, tags: [], level: 1, iniMod: 5, currentIni: 12,
        hp: 20, wounds: nil, currentConditions: nil, ac: 15, fortST: 5, refST: 5, willST: 5, dc: 15)
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
