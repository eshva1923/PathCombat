import SwiftUI

func pickerSheetEmptyMessage(noun: String, searchText: String) -> String {
    searchText.isEmpty ? "No \(noun) available in the library" : "No \(noun) match \"\(searchText)\""
}

struct PickerSheet<Accessory: View, ListContent: View, Footer: View>: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    @Binding var searchText: String
    let isEmpty: Bool
    let emptyMessage: String
    var addButtonTitle: String = "Add"
    let isAddDisabled: Bool
    let onAdd: () -> Void
    @ViewBuilder let accessory: () -> Accessory
    @ViewBuilder let listContent: () -> ListContent
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
            accessory()
            Divider()
            if isEmpty {
                Spacer()
                Text(emptyMessage)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ScrollView {
                    listContent()
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
