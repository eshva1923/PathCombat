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
    @State private var viewModel: CombatEntityViewModel

    let formatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            return formatter
    }()

    init(combatEntity: CombatEntity) {
        self.combatEntity = combatEntity
        self._viewModel = State(initialValue: CombatEntityViewModel(combatEntity: combatEntity))
    }
    
    var body: some View {
        Group {
            HStack{
                TextField(text: $combatEntity.name) {
                    Image(systemName: "figure.stand")
                }.font(.title)
                    .fontDesign(.serif)
                    .fontWeight(.bold)
                levelTag
            }
            .padding(.vertical)
            HStack{
                ForEach (combatEntity.tags, id: \.self) {tag in
                    LabelTag(text: tag, color: .accentColor)
                }
            }
            StatRow
                HStack {
                    initiativeSection
                    hpSection
                    
                }.padding(.horizontal, 10)   
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
                Text("max HP")
                    .fontWeight(.bold)
                TextField(value: $combatEntity.totalHP,
                          formatter: formatter) {
                    Image(systemName: "heart.fill")
                }.fontWeight(.bold)
                Spacer()
                Image(systemName: "heart")
                Text("curr HP")
                    .fontWeight(.medium)
                TextField(value: $combatEntity.currentHP,
                          formatter: formatter) {
                    Image(systemName: "heart.fill")
                }.fontWeight(.medium)
            }
        
    }
    
    var StatRow: some View {
        Group {
            HStack {
            LabelStat(
                text: "Fortitude",
                value: $combatEntity.fortST,
                imageName: "figure.boxing",
                hoverEffect: true,
                hoverColor: nil)
            LabelStat(
                text: "Reflexes",
                value: $combatEntity.refST,
                imageName: "figure.fall",
                hoverEffect: true,
                hoverColor: nil)
            LabelStat(
                text: "Will",
                value: $combatEntity.willST,
                imageName: "brain.fill",
                hoverEffect: true,
                hoverColor: nil)
            LabelStat(
                text: "Perception",
                value: $combatEntity.iniMod,
                imageName: "bolt",
                hoverEffect: true,
                hoverColor: Color.orange)
            
        }
            HStack {
                LabelStat(
                    text: "AC",
                    value: $combatEntity.ac,
                    imageName: "shield.lefthalf.filled",
                    hoverEffect: false,
                    hoverColor: nil)
                LabelStat(
                    text: "DC",
                    value: $combatEntity.dc,
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
