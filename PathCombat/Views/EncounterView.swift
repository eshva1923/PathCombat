import SwiftUI
import SwiftData

struct EncounterView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var encounter: Encounter
    
    var body: some View {
        Form {
            Section(header: Text("Info")) {
                topRow
                Divider().padding()
                ForEach(encounter.combatEntities) { entity in
                        CombatEntityView(combatEntity: entity)
                    HStack {
                        Button {
                            deleteEntity(entity)
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                        Divider().padding()
                }
                addEntityRow
                Divider().padding()
                HStack {
                    Spacer()
                    Text("Added on:")
                        .italic()
                    Text(dateAdded)
                        .italic()
                }
            }
        }
        .padding()
        .navigationTitle(encounter.name)
    }
}

extension EncounterView {
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
