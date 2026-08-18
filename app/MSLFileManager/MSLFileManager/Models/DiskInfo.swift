import Foundation

struct DiskInfo: Identifiable, Sendable {
    let id: String
    let devicePath: String
    let volumeName: String
    let filesystemType: String
    let isNTFS: Bool
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
