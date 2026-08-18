import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var state: AppState
    @ObservedObject var browserViewModel: BrowserViewModel

    var body: some View {
        List(selection: Binding(
            get: { state.sidebarSelection },
            set: { state.sidebarSelection = $0 }
        )) {
            Section("Favorites") {
                SidebarItemRow(item: .home, icon: "house.fill", color: .purple)
                SidebarItemRow(item: .desktop, icon: "desktopcomputer", color: .orange)
                SidebarItemRow(item: .documents, icon: "doc.fill", color: .blue)
                SidebarItemRow(item: .downloads, icon: "arrow.down.circle.fill", color: .green)
                SidebarItemRow(item: .applications, icon: "app.fill", color: .blue)
            }

            Section("Linux VM") {
                SidebarItemRow(item: .vm, icon: "terminal.fill", color: .green)

                if state.diskMonitor.allExternalDisks.isEmpty {
                    Text("No external disks")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(state.diskMonitor.allExternalDisks) { disk in
                        SidebarItemRow(
                            item: .vmDisk(disk.id),
                            icon: "externaldrive.fill",
                            color: disk.isLinuxCompatible ? .orange : .gray
                        )
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("MSL FileManager")
    }
}

struct SidebarItemRow: View {
    let item: SidebarItem
    let icon: String
    let color: Color

    var body: some View {
        Label {
            Text(item.displayName)
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(color)
        }
        .tag(item)
    }
}
