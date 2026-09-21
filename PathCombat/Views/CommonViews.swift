//
//  CommonViews.swift
//  PathCombat
//
//  Created by Federico Brandani on 21/09/2026.
//
import SwiftUI

struct LabelTag: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .padding(3)
            .background(color)
            .cornerRadius(5)
    }
}

struct LabelStat: View {
    let text: String
    let value: Int
    let imageName: String
    let hoverEffect: Bool
    let hoverColor: Color?

    @State var backgroundColor = Color.clear
    
    var body: some View {
        Label {
            HStack {
                Text("\(value)")
                    .font(.title3)
                    .fontWeight(.bold)
                Text(text)
            }
        } icon: {
            Image(systemName: imageName)
        }
        .padding(4)
        .background(backgroundColor)
        .cornerRadius(4)
        .onHover { hovering in
            guard hoverEffect else { return }
            let hoveringColor = hoverColor ?? Color.secondary
            backgroundColor = hovering ? hoveringColor : Color.clear
        }
    }
}
