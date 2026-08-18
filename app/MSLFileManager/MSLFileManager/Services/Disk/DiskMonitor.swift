import Foundation

@Observable
@MainActor
final class DiskMonitor {
    var allDisks: [DiskInfo] = []
    var ntfsDisks: [DiskInfo] { allDisks.filter(\.isNTFS) }
    var mountedVolumes: [DiskInfo] { allDisks.filter { $0.mountPoint != nil } }

    func start() {
        Task { await refreshDisks() }
    }

    func stop() {}

    func refreshDisks() async {
        let output = try? await VMCommandService().execute("diskutil list external -plist 2>/dev/null || true")
        guard let output, let data = output.data(using: .utf8) else { return }

        if let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
           let disks = plist["AllDisksAndPartitions"] as? [[String: Any]] {
            var result: [DiskInfo] = []
            for disk in disks {
                guard let devID = disk["DeviceIdentifier"] as? String else { continue }
                let size = disk["Size"] as? Int64 ?? 0
                let partitions = disk["Partitions"] as? [[String: Any]] ?? []

                for part in partitions {
                    guard let volName = part["VolumeName"] as? String else { continue }
                    let fsType = part["FilesystemType"] as? String ?? ""
                    let mount = part["MountPoint"] as? String
                    let isNTFS = fsType.lowercased().contains("ntfs")

                    result.append(DiskInfo(
                        id: "/dev/\(devID)s\(part["PartitionNumber"] ?? "")",
                        devicePath: "/dev/\(devID)",
                        volumeName: volName,
                        filesystemType: fsType,
                        isNTFS: isNTFS,
                        mountPoint: mount.map { URL(fileURLWithPath: $0) },
                        size: size,
                        isRemovable: true
                    ))
                }
            }
            allDisks = result
        }
    }
}
