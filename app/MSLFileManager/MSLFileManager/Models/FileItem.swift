import Foundation
import AppKit

struct FileItem: Identifiable, Sendable {
    let id: String
    let name: String
    let url: URL?
    let remotePath: String?
    let isDirectory: Bool
    let size: Int64
    let modificationDate: Date
    let typeIdentifier: String
    let isHidden: Bool
    let isRemote: Bool
    let permissions: String?

    var icon: NSImage {
        if let url {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return NSWorkspace.shared.icon(forFileType: typeIdentifier)
    }

    var displaySize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: modificationDate)
    }

    static func local(url: URL) -> FileItem {
        let resourceValues = try? url.resourceValues(forKeys: [
            .isDirectoryKey,
            .fileSizeKey,
            .contentModificationDateKey,
            .typeIdentifierKey,
            .isHiddenKey
        ])

        return FileItem(
            id: url.path,
            name: url.lastPathComponent,
            url: url,
            remotePath: nil,
            isDirectory: resourceValues?.isDirectory ?? false,
            size: Int64(resourceValues?.fileSize ?? 0),
            modificationDate: resourceValues?.contentModificationDate ?? Date(),
            typeIdentifier: resourceValues?.typeIdentifier ?? "public.item",
            isHidden: resourceValues?.isHidden ?? false,
            isRemote: false,
            permissions: nil
        )
    }

    static func remote(path: String, name: String, isDirectory: Bool, size: Int64, modificationDate: Date, permissions: String?) -> FileItem {
        let ext = (name as NSString).pathExtension
        let typeIdentifier = UTType(filenameExtension: ext)?.identifier ?? "public.item"

        return FileItem(
            id: "remote:\(path)",
            name: name,
            url: nil,
            remotePath: path,
            isDirectory: isDirectory,
            size: size,
            modificationDate: modificationDate,
            typeIdentifier: typeIdentifier,
            isHidden: name.hasPrefix("."),
            isRemote: true,
            permissions: permissions
        )
    }
}
