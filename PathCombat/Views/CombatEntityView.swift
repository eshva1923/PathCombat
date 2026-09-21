//
//  CombatEntityView.swift
//  PathCombat
//
//  Created by Federico Brandani on 21/09/2026.
//

import SwiftUI
import SwiftData

struct CombatEntityView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var combatEntity: CombatEntity
    
    let formatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            return formatter
    }()
    
    
    var body: some View {
        Group {
            HStack{
                TextField(text: $combatEntity.name) {
                    Image(systemName: "figure.stand")
                }.font(.title)
                    .fontDesign(.serif)
                    .fontWeight(.bold)
                LabelTag(text: "Level \(combatEntity.level)", color: .brown)
            }
            .padding(.vertical)
            HStack{
                ForEach (combatEntity.tags, id: \.self) {tag in
                    LabelTag(text: tag, color: .accentColor)
                }
            }
            StatRow
            Section {
                HStack {
                    hpSection
                    Divider()
                    initiativeSection
                }
            }.padding(.horizontal, 10)
        }.frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
            
            
    
    var initiativeSection: some View {
        VStack {
            HStack {
                Image(systemName: "figure.run")
                Text("Initiative")
                    .font(.title)
                    .fontWeight(.bold)
            }
            HStack {
                TextField(value: $combatEntity.currentIni,
                          formatter: formatter) {
                    HStack {
                        Image(systemName: "figure.run")
                        Text("INI")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                }
                Button {
                    rollIni()
                } label: {
                    VStack {
                        Text("Roll Initiative")
                        Image(systemName: "figure.run.circle")
                    }
                }
            }
        }
    }
    
    var hpSection: some View {
        VStack {
            HStack {
                Image(systemName: "heart.fill")
                Text("HP")
                    .font(.title)
                    .fontWeight(.bold)
            }
            HStack {
                TextField(value: $combatEntity.currentHP,
                          formatter: formatter) {
                    HStack {
                        Image(systemName: "heart.fill")
                        Text("HP")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("\(combatEntity.totalHP) / ")
                            .font(.title2)
                            .fontWeight(.medium)
                    }
                }
                Button {
                    removeHP()
                } label: {
                    VStack {
                        Text("Remove HP")
                        Image(systemName: "minus")
                    }
                }
                
                Button {
                    addHP()
                } label: {
                    VStack {
                        Text("Add HP")
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    func addHP() {
        // popup dialog
    }
    
    func removeHP() {
        //popup dialog
    }
    
    func rollIni() {
        let initiative = DieType.d20.roll() + combatEntity.iniMod
        combatEntity.currentIni = initiative
    }
    
    var StatRow: some View {
        Group {
            HStack {
            LabelStat(
                text: "Fortitude",
                value: combatEntity.fortST,
                imageName: "figure.boxing",
                hoverEffect: true,
                hoverColor: nil)
            LabelStat(
                text: "Reflexes",
                value: combatEntity.refST,
                imageName: "figure.fall",
                hoverEffect: true,
                hoverColor: nil)
            LabelStat(
                text: "Will",
                value: combatEntity.willST,
                imageName: "brain.fill",
                hoverEffect: true,
                hoverColor: nil)
            LabelStat(
                text: "Perception",
                value: combatEntity.iniMod,
                imageName: "bolt",
                hoverEffect: true,
                hoverColor: Color.orange)
            
        }
            HStack {
                LabelStat(
                    text: "AC",
                    value: combatEntity.ac,
                    imageName: "shield.lefthalf.filled",
                    hoverEffect: false,
                    hoverColor: nil)
                LabelStat(
                    text: "DC",
                    value: combatEntity.dc,
                    imageName: "dot.scope",
                    hoverEffect: false,
                    hoverColor: nil)
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
        totalHP: 200,
        currentHP: nil,
        currentConditions: nil,
        ac: 25,
        fortST: 12,
        refST: 8,
        willST: 21,
        dc: 21)

    CombatEntityView(combatEntity: entity)
}
