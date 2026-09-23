import SwiftUI
import SwiftData

struct EncounterView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var encounter: Encounter
    @State private var viewModel: EncounterViewModel

    init(encounter: Encounter) {
        self.encounter = encounter
        self._viewModel = State(initialValue: EncounterViewModel(encounter: encounter))
    }

    var sortedByInitiative: [CombatEntity] {
        encounter.combatEntities.sorted { lhs, rhs in
            if lhs.currentIni != rhs.currentIni {
                return lhs.currentIni > rhs.currentIni
            }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    var dateAdded: String {
        encounter.date.formatted(date: .long, time: .shortened)
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
                        Text(dateAdded)
                            .italic()
                    }
                    .padding()
                }
                .frame(minWidth: 300)
                initiativeTracker(proxy: proxy)
                    .frame(minWidth: 160, idealWidth: 160, maxWidth: 400)
            }
            .navigationTitle(encounter.name)
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
                    viewModel.advanceInitiative()
                } label: {
                    Image(systemName: "play.fill")
                }
                .disabled(encounter.combatEntities.isEmpty)
            }.padding()
            if encounter.combatEntities.isEmpty {
                Text("No entities added")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                List(sortedByInitiative) { entity in
                    Button {
                        withAnimation {
                            proxy.scrollTo(entity.id, anchor: .top)
                        }
                    } label: {
                        HStack {
                            Text(entity.name)
                                .lineLimit(1)
                            Spacer()
                            HStack {
                                VStack {
                                    Image(systemName: "figure.run")
                                    Text("\(entity.currentIni)")
                                        .fontWeight(.bold)
                                }
                                VStack {
                                    Image(systemName: "heart.fill")
                                    Text("\(entity.totalHP)")
                                        .fontWeight(.bold)
                                }
                                VStack {
                                    Image(systemName: "heart")
                                    Text("\(entity.currentHP)")
                                        .fontWeight(.bold)
                                }
                                
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(entity.id == encounter.actingEntity ? Color.secondary : Color.clear)
                }
                .listStyle(.plain)
            }
        }
    }

    var addEntityRow: some View {
        Button {
            viewModel.addNewEntity()
        } label: {
            HStack {
                Spacer()
                Image(systemName: "plus.app")
                Spacer()
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
    
    
    var topRow: some View {
        HStack {
            TextField("Encounter name", text: $encounter.name)
            Text("Difficulty: ")
            LabelTag(
                text: encounter.calculateDifficulty().rawValue,
                color: .blue)
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
                     totalHP: 200,
                     currentHP: nil,
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
