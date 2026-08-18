import Foundation

struct DiskInfo: Identifiable, Hashable, Sendable {
    let id: String
    let devicePath: String
    let volumeName: String
    let filesystemType: String
    let isLinuxCompatible: Bool
    let mountPoint: URL?
    let size: Int64?
    let isRemovable: Bool

    var displayName: String {
        volumeName.isEmpty ? (URL(fileURLWithPath: devicePath).lastPathComponent) : volumeName
    }

    var displaySize: String {
        guard let size else { return "Unknown" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var fsTypeDisplay: String {
        filesystemType.uppercased()
    }
}

enum MountState: Sendable {
    case idle
    case mounting
    case mounted
    case unmounting
    case failed(String)
}

struct VMDisk: Identifiable, Sendable {
    let id: String
    let devicePath: String
    let volumeName: String
    let vmMountPath: String
    let hostMountPoint: String
    let isMounted: Bool

    var displayName: String {
        volumeName.isEmpty ? URL(fileURLWithPath: devicePath).lastPathComponent : volumeName
    }
}
