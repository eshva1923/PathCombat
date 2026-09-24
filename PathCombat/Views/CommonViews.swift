//
//  CommonViews.swift
//  PathCombat
//
//  Created by Federico Brandani on 21/09/2026.
//
import SwiftUI

extension Color {
    static let navy = Color(red: 0.0, green: 0.0, blue: 0.5)

    /// Badge color for the PC/Boss role labels shown next to an entity's name.
    static func roleBadgeColor(for role: CombatRole) -> Color {
        switch role {
        case .boss:
            return Color(red: 0.55, green: 0.0, blue: 0.0)
        case .pc:
            return .purple
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

/// A condition pill that shows a quick description callout on hover, and a
/// full-size detail sheet on click (for descriptions that need more room).
/// Both use a regular background with the tag's color only as a border.
struct ConditionTag: View {
    let text: String
    let description: String
    let color: Color
    var value: Binding<String>? = nil
    var onDelete: (() -> Void)? = nil

    @State private var isHovering = false
    @State private var isShowingDetail = false

    var body: some View {
        Text(text)
            .padding(3)
            .background(color)
            .cornerRadius(5)
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovering = hovering
            }
            .onTapGesture {
                isHovering = false
                // Defer to the next runloop tick so the popover's dismissal transaction
                // commits before the sheet's presentation transaction begins; presenting
                // both in the same cycle drops the sheet and logs a CA transaction warning.
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
                            TextField("-", text: value)
                                .frame(width: 60)
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
