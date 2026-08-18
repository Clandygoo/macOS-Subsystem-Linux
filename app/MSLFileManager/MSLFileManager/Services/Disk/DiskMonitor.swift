import Foundation

final class DiskMonitor: ObservableObject {
    @Published var allDisks: [DiskInfo] = []
    var allExternalDisks: [DiskInfo] { allDisks }
    var mountedVolumes: [DiskInfo] { allDisks.filter { $0.mountPoint != nil } }

    func start() {
        Task { await refreshDisks() }
    }

    func stop() {}

    func refreshDisks() async {
        let output = try? await VMCommandService().execute("diskutil list -plist 2>/dev/null || true")
        guard let output, let data = output.data(using: .utf8) else { return }

        if let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
           let allDisksList = plist["AllDisksAndPartitions"] as? [[String: Any]] {
            var result: [DiskInfo] = []
            for disk in allDisksList {
                guard let devID = disk["DeviceIdentifier"] as? String else { continue }
                let size = disk["Size"] as? Int64 ?? 0
                let partitions = disk["Partitions"] as? [[String: Any]] ?? []

                for part in partitions {
                    let volName = part["VolumeName"] as? String ?? ""
                    let fsType = part["FilesystemType"] as? String ?? ""
                    let mount = part["MountPoint"] as? String
                    let partNum = part["PartitionNumber"] as? Int ?? 0
                    let isLinuxCompatible = Self.isLinuxCompatible(fsType)

                    guard !fsType.isEmpty, isLinuxCompatible else { continue }

                    let isRemovable = devID.contains("disk") && (devID.contains("external") || devID.hasPrefix("disk") && Int(devID.replacingOccurrences(of: "disk", with: "")) ?? 0 > 0)

                    result.append(DiskInfo(
                        id: "/dev/\(devID)s\(partNum)",
                        devicePath: "/dev/\(devID)",
                        volumeName: volName,
                        filesystemType: fsType,
                        isLinuxCompatible: isLinuxCompatible,
                        mountPoint: mount.map { URL(fileURLWithPath: $0) },
                        size: size,
                        isRemovable: isRemovable
                    ))
                }
            }
            allDisks = result
        }
    }

    static func isLinuxCompatible(_ fsType: String) -> Bool {
        let lower = fsType.lowercased()
        let compatible = ["ntfs", "ext2", "ext3", "ext4", "btrfs", "xfs",
                          "fat32", "vfat", "exfat", "apfs", "hfs+", "hfs",
                          "udf", "iso9660"]
        return compatible.contains { lower.contains($0) }
    }
}
