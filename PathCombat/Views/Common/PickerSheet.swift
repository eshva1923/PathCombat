import SwiftUI

/// The shared shell for "pick one item from a searchable list, then Add" sheets used by the
/// condition/spell/entity pickers: a title, a search field, a scrollable list of rows (or an
/// empty-state message), an optional footer above the button row, and Cancel/Add buttons.
struct PickerSheet<Item: Identifiable, Row: View, Footer: View>: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let items: [Item]
    let noun: String
    @Binding var searchText: String
    var addButtonTitle: String = "Add"
    let isAddDisabled: Bool
    let onAdd: () -> Void
    @ViewBuilder let row: (Item) -> Row
    @ViewBuilder let footer: () -> Footer

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            SearchField(text: $searchText)
                .padding(.horizontal)
                .padding(.bottom, 8)
            Divider()
            if items.isEmpty {
                Spacer()
                Text(searchText.isEmpty ? "No \(noun) available in the library" : "No \(noun) match \"\(searchText)\"")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(items) { item in
                            row(item)
                            Divider()
                        }
                    }
                }
            }
            Divider()
            footer()
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
                Button(addButtonTitle) {
                    onAdd()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isAddDisabled)
            }
            .padding()
        }
        .frame(minWidth: 440, minHeight: 380)
    }
}
