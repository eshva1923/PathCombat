import SwiftUI

private let minSplitViewWidth = 180.0
private let idealSplitViewWidth = 200.0
private let maxSplitViewWidth = 220.0

/// The shared `NavigationSplitView` shell for every library screen (Spells, Rules and
/// Conditions, Entities, Combat Tracker): a fixed-width sidebar with a search field on top and
/// the caller's `sidebarContent` below, and a `detail` pane. Owns `columnVisibility` and snaps
/// it back to `.all` on any change, since there's no sidebar-toggle button (it's removed) to
/// bring a collapsed sidebar back.
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
