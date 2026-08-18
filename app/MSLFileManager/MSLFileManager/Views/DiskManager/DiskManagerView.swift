import SwiftUI

struct DiskManagerView: View {
    @Environment(AppState.self) private var state
    @State private var selectedDisk: DiskInfo?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Disk Manager")
                    .font(.headline)
                Spacer()
                Button {
                    Task {
                        await state.diskMonitor.refreshDisks()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .padding()

            Divider()

            if state.diskMonitor.ntfsDisks.isEmpty {
                ContentUnavailableView(
                    "No NTFS Disks",
                    systemImage: "externaldrive.badge.xmark",
                    description: Text("Connect an NTFS-formatted disk")
                )
            } else {
                List(state.diskMonitor.ntfsDisks, selection: $selectedDisk) { disk in
                    DiskRowView(disk: disk)
                        .tag(disk)
                }
            }

            Divider()

            HStack {
                Button("Mount All") {
                    Task {
                        await state.ntfsMountService.autoMountAll(state.diskMonitor.ntfsDisks)
                    }
                }

                Button("Unmount All") {
                    Task {
                        await state.ntfsMountService.unmountAll()
                    }
                }

                Spacer()

                if let disk = selectedDisk {
                    Button("Mount Selected") {
                        Task {
                            await state.ntfsMountService.mountDisk(disk)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct DiskRowView: View {
    let disk: DiskInfo

    var body: some View {
        HStack {
            Image(systemName: "externaldrive.fill")
                .foregroundStyle(.orange)
                .frame(width: 24)

            VStack(alignment: .leading) {
                Text(disk.displayName)
                    .font(.body)
                Text(disk.displaySize)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if disk.isNTFS {
                Text("NTFS")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(4)
            }

            if disk.mountPoint != nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
    }
}
