import Foundation

final class NTFSMountService: ObservableObject {
    @Published var mountedDisks: [VMDisk] = []
    @Published var mountProgress: [String: MountState] = [:]

    private let lima = LimaService()
    private let vmCommand = VMCommandService()

    func autoMountAll(_ disks: [DiskInfo]) async {
        for disk in disks where disk.isNTFS {
            await mountDisk(disk)
        }
    }

    func mountDisk(_ disk: DiskInfo) async {
        let diskId = URL(fileURLWithPath: disk.devicePath).lastPathComponent
        mountProgress[diskId] = .mounting

        do {
            let vmMountPath = "\(Constants.vmNTFSMountBase)/\(diskId)"
            _ = try await lima.shell("sudo mkdir -p \(vmMountPath)")

            if let hostPath = disk.mountPoint?.path {
                _ = try await lima.shell("sudo mount -t virtiofs \(hostPath) \(vmMountPath) 2>/dev/null || true")
            }

            let vmDisk = VMDisk(
                id: disk.id,
                devicePath: disk.devicePath,
                volumeName: disk.volumeName,
                vmMountPath: vmMountPath,
                hostMountPoint: disk.mountPoint?.path ?? "",
                isMounted: true
            )

            mountedDisks.append(vmDisk)
            mountProgress[diskId] = .mounted
        } catch {
            mountProgress[diskId] = .failed(error.localizedDescription)
        }
    }

    func unmountDisk(_ disk: VMDisk) async {
        let diskId = URL(fileURLWithPath: disk.devicePath).lastPathComponent
        mountProgress[diskId] = .unmounting

        _ = try? await lima.shell("sudo umount \(disk.vmMountPath) 2>/dev/null")

        mountedDisks.removeAll { $0.id == disk.id }
        mountProgress.removeValue(forKey: diskId)
    }

    func unmountAll() async {
        for disk in mountedDisks {
            await unmountDisk(disk)
        }
    }
}
