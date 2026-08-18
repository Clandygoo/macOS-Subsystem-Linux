import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var state: AppState
    @ObservedObject var browserViewModel: BrowserViewModel

    var body: some View {
        List(selection: Binding(
            get: { state.sidebarSelection },
            set: { state.sidebarSelection = $0 }
        )) {
            Section(L10n.t("sidebar.favorites")) {
                SidebarItemRow(item: .home, icon: "house.fill", color: .purple)
                SidebarItemRow(item: .desktop, icon: "desktopcomputer", color: .orange)
                SidebarItemRow(item: .documents, icon: "doc.fill", color: .blue)
                SidebarItemRow(item: .downloads, icon: "arrow.down.circle.fill", color: .green)
                SidebarItemRow(item: .applications, icon: "app.fill", color: .blue)
            }

            Section(L10n.t("sidebar.linux_vm")) {
                SidebarItemRow(item: .vm, icon: "terminal.fill", color: .green)

                if state.diskMonitor.allExternalDisks.isEmpty {
                    Text(L10n.t("sidebar.no_disks"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(state.diskMonitor.allExternalDisks) { disk in
                        HStack {
                            Image(systemName: "externaldrive.fill")
                                .foregroundStyle(disk.isLinuxCompatible ? .orange : .gray)
                            Text(disk.displayName)
                            Spacer()
                            Text(disk.fsTypeDisplay)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .tag(SidebarItem.vmDisk(disk.id))
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle(L10n.t("app.name"))
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
