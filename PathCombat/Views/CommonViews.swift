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
    let imageName: String?
    let hoverEffect: Bool
    let hoverColor: Color?

    @State var backgroundColor = Color.clear
    
    var body: some View {
        HStack {
            if let imageName {
                Image(systemName: imageName)
            }
            Text(text)
                .padding(3)
                .background(color)
                .cornerRadius(5)
        }
        .onHover { hovering in
            guard hoverEffect else { return }
            let hoverColor = hoverColor ?? Color.secondary
            backgroundColor = hovering ? hoverColor: Color.clear
        }
    }
}

struct LabelStat: View {
    let text: String
    @Binding var value: Int
    let imageName: String
    let hoverEffect: Bool
    let hoverColor: Color?
    var isEditable: Bool = true

    @State var backgroundColor = Color.clear

    static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    var body: some View {
        Label {
            HStack {
                if isEditable {
                    TextField(value: $value, formatter: Self.formatter) {
                        EmptyView()
                    }
                    .font(.title3)
                    .fontWeight(.bold)
                    .frame(width: 40)
                } else {
                    Text("\(value)")
                        .font(.title3)
                        .fontWeight(.bold)
                }
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
