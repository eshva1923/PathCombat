import SwiftUI
import SwiftData

struct EncounterView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var encounter: Encounter
    
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
                                            deleteEntity(entity)
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
    var sortedByInitiative: [CombatEntity] {
        encounter.combatEntities.sorted { lhs, rhs in
            if lhs.currentIni != rhs.currentIni {
                return lhs.currentIni > rhs.currentIni
            }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    func initiativeTracker(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Initiative")
                    .font(.headline)
                    .fontDesign(.serif)

                Spacer()
                Button {
                    advanceInitiative()
                } label: {
                    Image(systemName: "play.fill")
                }
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
        HStack {
            Spacer()
            Button {
                addNewEntity()
            } label: {
                Image(systemName: "plus.app")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 5)
                
            }
            Spacer()
        }
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
    var dateAdded: String {
        encounter.date.formatted(date: .long, time: .shortened)
    }
    
    private func addNewEntity() {
        withAnimation {
            encounter.combatEntities.append(CombatEntity.new())
        }
    }
    
    private func deleteEntity(_ entity: CombatEntity) {
        withAnimation {
            encounter.combatEntities.removeAll(where: {$0 == entity})
        }
    }
    
    private func advanceInitiative() {
        let order = sortedByInitiative
        guard !order.isEmpty else { return }

        guard encounter.currentInitiative != 0,
              let actingID = encounter.actingEntity,
              let currentIndex = order.firstIndex(where: { $0.id == actingID }) else {
            let first = order.first!
            encounter.currentInitiative = first.currentIni
            encounter.actingEntity = first.id
            return
        }

        let nextIndex = currentIndex + 1
        if nextIndex < order.count {
            let next = order[nextIndex]
            encounter.currentInitiative = next.currentIni
            encounter.actingEntity = next.id
        } else {
            let first = order.first!
            encounter.currentInitiative = first.currentIni
            encounter.actingEntity = first.id
            encounter.elapsedCombatRounds += 1
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
