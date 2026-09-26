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

/// The search field used at the top of every library/tracker sidebar and picker sheet:
/// a search icon, a select-all-on-focus text field, and a clear button that appears once
/// there's text. Callers own their own outer padding, since that varies by context.
struct SearchField: View {
    @Binding var text: String
    var placeholder: String = ""

    var body: some View {
        HStack {
            Icons.search.foregroundStyle(.secondary)
            SelectAllTextField(placeholder, text: $text)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// A tappable, collapsible section header (chevron rotates to indicate expanded state) used
/// by every sidebar that groups its rows into sections. Callers supply the leading content
/// (label text, optional trailing icon) via `content`; this owns the chevron, background,
/// and toggle behavior shared by every section header.
struct CollapsibleSectionHeader<Content: View>: View {
    let isExpanded: Bool
    let onToggle: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        Button(action: onToggle) {
            HStack {
                content()
                Image(systemName: "chevron.right")
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .background(Color.secondary.opacity(0.5))
        }
        .buttonStyle(.plain)
    }
}

/// A selectable, hoverable sidebar/picker row: tapping selects it, hovering reveals an
/// optional trailing delete button, and the background reflects selected/hovered state.
/// Used by every library sidebar row and picker-sheet row — callers supply only the row's
/// own content.
struct LibraryRow<Content: View>: View {
    let isSelected: Bool
    let onSelect: () -> Void
    var onDelete: (() -> Void)? = nil
    var deleteHelpText: String? = nil
    @ViewBuilder let content: () -> Content

    @State private var isHovering = false

    var body: some View {
        HStack {
            Button(action: onSelect) {
                content()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
                .opacity(isHovering ? 1 : 0)
                .help(deleteHelpText ?? "")
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            isSelected ? Color.accentColor.opacity(0.25) : (isHovering ? Color.secondary.opacity(0.15) : Color.clear)
        )
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

/// The "create a new X" placeholder shown in a detail pane when nothing is selected.
struct CreateNewItemButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Icons.addCircle
                    .font(.largeTitle)
                Text(title)
            }
        }
        .buttonStyle(.plain)
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
                        Icons.spellRank(spell.level)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text(CombatAction.speedSymbol(for: spell.speed))
                        if !spell.range.isEmpty {
                            Text("Range: \(spell.range)")
                        }
                        if !spell.area.isEmpty {
                            Text("Area: \(spell.area)")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
