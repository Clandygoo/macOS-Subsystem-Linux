import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        List(selection: Binding(
            get: { state.sidebarSelection },
            set: { state.sidebarSelection = $0 }
        )) {
            Section("Favorites") {
                SidebarItemRow(item: .favorites, icon: "star.fill", color: .yellow)
                SidebarItemRow(item: .recent, icon: "clock.fill", color: .gray)
                SidebarItemRow(item: .applications, icon: "app.fill", color: .blue)
                SidebarItemRow(item: .desktop, icon: "desktopcomputer", color: .orange)
                SidebarItemRow(item: .documents, icon: "doc.fill", color: .blue)
                SidebarItemRow(item: .downloads, icon: "arrow.down.circle.fill", color: .green)
                SidebarItemRow(item: .home, icon: "house.fill", color: .purple)
            }

            Section("Linux VM") {
                SidebarItemRow(item: .vm, icon: "terminal.fill", color: .green)

                if state.diskMonitor.ntfsDisks.isEmpty {
                    Text("No NTFS disks")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(state.diskMonitor.ntfsDisks) { disk in
                        SidebarItemRow(
                            item: .vmDisk(disk.id),
                            icon: "externaldrive.fill",
                            color: .orange
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
