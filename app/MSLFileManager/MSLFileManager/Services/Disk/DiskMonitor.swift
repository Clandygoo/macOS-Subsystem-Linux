import Foundation
import DiskArbitration

@Observable
@MainActor
final class DiskMonitor {
    var allDisks: [DiskInfo] = []
    var ntfsDisks: [DiskInfo] { allDisks.filter(\.isNTFS) }
    var mountedVolumes: [DiskInfo] { allDisks.filter { $0.mountPoint != nil } }

    private var session: DASession?
    private var onDiskAppeared: ((DiskInfo) -> Void)?
    private var onDiskDisappeared: ((String) -> Void)?

    func start() {
        session = DASessionCreate(kCFAllocatorDefault)

        guard let session else { return }

        let context = Unmanaged.passUnretained(self).toOpaque()

        DARegisterDiskAppearedCallback(
            session,
            nil,
            { disk, context in
                guard let context else { return }
                let monitor = Unmanaged<DiskMonitor>.fromOpaque(context).takeUnretainedValue()
                monitor.handleDiskAppeared(disk)
            },
            context
        )

        DARegisterDiskDisappearedCallback(
            session,
            nil,
            { disk, context in
                guard let context,
                      let devicePath = DADiskCopyDevicePath(disk) as String? else { return }
                let monitor = Unmanaged<DiskMonitor>.fromOpaque(context).takeUnretainedValue()
                Task { @MainActor in
                    monitor.allDisks.removeAll { $0.devicePath == devicePath }
                }
            },
            context
        )

        DASessionScheduleWithRunLoop(session, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
    }

    func stop() {
        if let session {
            DAUnregisterCallback(session, { _, _ in } as DADiskAppearedCallback)
            DASessionUnscheduleFromRunLoop(session, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        }
        session = nil
    }

    private func handleDiskAppeared(_ disk: DADisk) {
        guard let description = DADiskCopyDescription(disk) as? [String: Any] else { return }

        let volumeName = description[kDADiskDescriptionVolumeNameKey] as? String ?? ""
        let filesystemType = description[kDADiskDescriptionFileSystemTypeKey] as? String ?? ""
        let devicePath = DADiskCopyDevicePath(disk) as String? ?? ""
        let volumePath = description[kDADiskDescriptionVolumePathKey] as? URL

        let isNTFS = filesystemType.lowercased().contains("ntfs") ||
                     filesystemType.contains("Windows_NTFS")

        let size = description[kDADiskDescriptionMediaSizeKey] as? Int64

        let diskInfo = DiskInfo(
            id: devicePath,
            devicePath: devicePath,
            volumeName: volumeName,
            filesystemType: filesystemType,
            isNTFS: isNTFS,
            mountPoint: volumePath,
            size: size,
            isRemovable: true
        )

        Task { @MainActor in
            if !self.allDisks.contains(where: { $0.devicePath == devicePath }) {
                self.allDisks.append(diskInfo)
            }
        }
    }

    func refreshDisks() async {
        let output = try? await VMCommandService().execute("diskutil list external -plist 2>/dev/null || true")
        guard let output, let data = output.data(using: .utf8) else { return }

        if let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
           let allDisks = plist["AllDisksAndPartitions"] as? [[String: Any]] {
            for disk in allDisks {
                guard let devicePath = disk["DeviceIdentifier"] as? String else { continue }
                let size = disk["Size"] as? Int64 ?? 0
                let partitions = disk["Partitions"] as? [[String: Any]] ?? []

                for partition in partitions {
                    guard let volName = partition["VolumeName"] as? String,
                          let fsType = partition["FilesystemType"] as? String,
                          fsType.lowercased() == "ntfs" else { continue }

                    let info = DiskInfo(
                        id: "/dev/\(devicePath)",
                        devicePath: "/dev/\(devicePath)",
                        volumeName: volName,
                        filesystemType: fsType,
                        isNTFS: true,
                        mountPoint: nil,
                        size: size,
                        isRemovable: true
                    )

                    if !self.allDisks.contains(where: { $0.id == info.id }) {
                        self.allDisks.append(info)
                    }
                }
            }
        }
    }
}
