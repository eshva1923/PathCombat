import SwiftUI

private let minSplitViewWidth = 180.0
private let idealSplitViewWidth = 200.0
private let maxSplitViewWidth = 220.0

struct LibrarySplitView<SidebarContent: View, Detail: View>: View {
    @Binding var searchText: String
    @ViewBuilder let sidebarContent: () -> SidebarContent
    @ViewBuilder let detail: () -> Detail

    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            VStack(spacing: 0) {
                SearchField(text: $searchText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                Divider()
                ScrollView(.vertical) {
                    sidebarContent()
                }
            }
            .navigationSplitViewColumnWidth(
                min: minSplitViewWidth,
                ideal: idealSplitViewWidth,
                max: maxSplitViewWidth
            )
            .toolbar(removing: .sidebarToggle)
        } detail: {
            detail()
        }
        .navigationSplitViewStyle(.prominentDetail)
        .onChange(of: columnVisibility) { _, newValue in
            if newValue != .all {
                columnVisibility = .all
            }
        }
    }
}
