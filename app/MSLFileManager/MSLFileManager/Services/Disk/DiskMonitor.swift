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
        var result: [DiskInfo] = []

        // Method 1: diskutil list external
        if let output = try? await VMCommandService().execute("diskutil list external -plist 2>/dev/null || true"),
           let data = output.data(using: .utf8),
           let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
           let disks = plist["AllDisksAndPartitions"] as? [[String: Any]] {
            result.append(contentsOf: parseDisks(disks, isExternal: true))
        }

        // Method 2: Check /Volumes/ for mounted external drives
        let volumes = (try? FileManager.default.contentsOfDirectory(atPath: "/Volumes")) ?? []
        let existingPaths = Set(result.map { $0.mountPoint?.path ?? "" })
        for vol in volumes {
            let volPath = "/Volumes/\(vol)"
            if !existingPaths.contains(volPath) && vol != "Macintosh HD" {
                let url = URL(fileURLWithPath: volPath)
                let resourceValues = try? url.resourceValues(forKeys: [.volumeLocalizedNameKey, .volumeAvailableCapacityKey, .fileSizeKey])
                let fsType = (try? url.resourceValues(forKeys: [.volumeLocalizedNameKey]))?.volumeLocalizedName ?? ""

                // Get filesystem type via diskutil
                let diskInfo = (try? await VMCommandService().execute("diskutil info \"\(volPath)\" 2>/dev/null | grep 'File System Personality' || true")) ?? ""
                let fs = diskInfo.replacingOccurrences(of: "File System Personality:", with: "").trimmingCharacters(in: .whitespaces)

                if !fs.isEmpty {
                    result.append(DiskInfo(
                        id: volPath,
                        devicePath: volPath,
                        volumeName: vol,
                        filesystemType: fs,
                        isLinuxCompatible: Self.isLinuxCompatible(fs),
                        mountPoint: url,
                        size: 0,
                        isRemovable: true
                    ))
                }
            }
        }

        allDisks = result
    }

    private func parseDisks(_ disks: [[String: Any]], isExternal: Bool) -> [DiskInfo] {
        var result: [DiskInfo] = []
        for disk in disks {
            guard let devID = disk["DeviceIdentifier"] as? String else { continue }
            let size = disk["Size"] as? Int64 ?? 0
            let partitions = disk["Partitions"] as? [[String: Any]] ?? []

            for part in partitions {
                let volName = part["VolumeName"] as? String ?? ""
                let fsType = part["FilesystemType"] as? String ?? ""
                let mount = part["MountPoint"] as? String
                let partNum = part["PartitionNumber"] as? Int ?? 0
                let isLinuxCompatible = Self.isLinuxCompatible(fsType)

                guard !fsType.isEmpty else { continue }

                result.append(DiskInfo(
                    id: "/dev/\(devID)s\(partNum)",
                    devicePath: "/dev/\(devID)",
                    volumeName: volName,
                    filesystemType: fsType,
                    isLinuxCompatible: isLinuxCompatible,
                    mountPoint: mount.map { URL(fileURLWithPath: $0) },
                    size: size,
                    isRemovable: isExternal
                ))
            }
        }
        return result
    }

    static func isLinuxCompatible(_ fsType: String) -> Bool {
        let lower = fsType.lowercased()
        let compatible = ["ntfs", "ext2", "ext3", "ext4", "btrfs", "xfs",
                          "fat32", "vfat", "exfat", "apfs", "hfs+", "hfs",
                          "udf", "iso9660"]
        return compatible.contains { lower.contains($0) }
    }
}
