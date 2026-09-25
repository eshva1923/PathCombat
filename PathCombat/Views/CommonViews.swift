//
//  CommonViews.swift
//  PathCombat
//
//  Created by Federico Brandani on 21/09/2026.
//
import SwiftUI
import AppKit

extension Color {
    static let navy = Color(red: 0.0, green: 0.0, blue: 0.5)
    static let darkRed = Color(red: 0.55, green: 0.0, blue: 0.0)

    static func roleBadgeColor(for role: CombatRole) -> Color {
        switch role {
        case .boss:
            return .darkRed
        case .pc:
            return .indigo
        default:
            return .accentColor
        }
    }
}

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

struct ConditionTag: View {
    let text: String
    let description: String
    let color: Color
    var isFilled: Bool = false
    var value: Binding<String>? = nil
    var damage: Binding<String>? = nil
    var onDelete: (() -> Void)? = nil

    @State private var isHovering = false
    @State private var isShowingDetail = false

    var body: some View {
        Text(text)
            .padding(3)
            .background(isFilled ? color : Color.secondary.opacity(0.15))
            .cornerRadius(5)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(color, lineWidth: 2)
            )
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovering = hovering
            }
            .onTapGesture {
                isHovering = false
                DispatchQueue.main.async {
                    isShowingDetail = true
                }
            }
            .popover(isPresented: $isHovering, arrowEdge: .bottom) {
                Text(description.isEmpty ? "No description" : description)
                    .padding()
                    .frame(maxWidth: 280, alignment: .leading)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(color, lineWidth: 3)
                    )
            }
            .sheet(isPresented: $isShowingDetail) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(text)
                        .font(.title2)
                        .fontWeight(.bold)
                    if let value {
                        HStack {
                            Text("Value")
                                .fontWeight(.semibold)
                            SelectAllTextField("-", text: value)
                                .frame(width: 60)
                        }
                    }
                    if let damage {
                        HStack {
                            Text("Damage")
                                .fontWeight(.semibold)
                            SelectAllTextField("e.g. 1d6 Acid", text: damage)
                        }
                    }
                    Divider()
                    ScrollView {
                        Text(description.isEmpty ? "No description" : description)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    HStack {
                        if let onDelete {
                            Button(role: .destructive) {
                                onDelete()
                                isShowingDetail = false
                            } label: {
                                Label("Remove Condition", systemImage: "trash")
                            }
                        }
                        Spacer()
                        Button("Close") {
                            isShowingDetail = false
                        }
                    }
                }
                .padding()
                .frame(minWidth: 360, minHeight: 260)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(color, lineWidth: 4)
                )
            }
    }
}

struct SpellTag: View {
    let spell: Spell
    var onDelete: (() -> Void)? = nil

    @State private var isHovering = false
    @State private var isShowingDetail = false

    var body: some View {
        Text(spell.name)
            .padding(3)
            .background(Color.secondary.opacity(0.15))
            .cornerRadius(5)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.accentColor, lineWidth: 2)
            )
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovering = hovering
            }
            .onTapGesture {
                isHovering = false
                DispatchQueue.main.async {
                    isShowingDetail = true
                }
            }
            .popover(isPresented: $isHovering, arrowEdge: .bottom) {
                Text(spell.details.isEmpty ? "No description" : spell.details)
                    .padding()
                    .frame(maxWidth: 280, alignment: .leading)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.accentColor, lineWidth: 3)
                    )
            }
            .sheet(isPresented: $isShowingDetail) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(spell.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(spell.level == 0 ? "Cantrip" : "Rank \(spell.level)")
                            .foregroundStyle(.secondary)
                    }
                    if !spell.traditions.isEmpty {
                        HStack {
                            ForEach(spell.traditions) { tradition in
                                LabelTag(text: tradition.rawValue, color: .accentColor, imageName: nil, hoverEffect: false, hoverColor: nil)
                            }
                        }
                    }
                    Divider()
                    ScrollView {
                        Text(spell.details.isEmpty ? "No description" : spell.details)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    HStack {
                        if let onDelete {
                            Button(role: .destructive) {
                                onDelete()
                                isShowingDetail = false
                            } label: {
                                Label("Remove Spell", systemImage: "trash")
                            }
                        }
                        if let aonURL = spell.aonURL {
                            Button {
                                NSWorkspace.shared.open(aonURL)
                            } label: {
                                Label("Open in AON", systemImage: "safari")
                            }
                        }
                        Spacer()
                        Button("Close") {
                            isShowingDetail = false
                        }
                    }
                }
                .padding()
                .frame(minWidth: 360, minHeight: 260)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.accentColor, lineWidth: 4)
                )
            }
    }
}

struct LabelStat: View {
    let text: String
    @Binding var value: Int
    let hoverEffect: Bool
    let hoverColor: Color?
    var isEditable: Bool = true
    let image: Image?

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
                    SelectAllIntField(value: $value, formatter: Self.formatter)
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
            if let image {
                image
            }
        }
        .padding(4)
        .background(backgroundColor)
        .cornerRadius(4)
        .onHover { hovering in
            guard hoverEffect else { return }
            let hoveringColor = hoverColor ?? Color.secondary
            backgroundColor = hovering ? hoveringColor.opacity(0.25) : Color.clear
        }
    }
}
