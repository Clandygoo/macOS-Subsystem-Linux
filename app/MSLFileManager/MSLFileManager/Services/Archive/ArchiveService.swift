import Foundation

struct ArchiveEntry: Identifiable {
    let id = UUID()
    let path: String
    let name: String
    let size: Int64
    let compressedSize: Int64?
    let isDirectory: Bool
    let modificationDate: Date?

    var displayName: String {
        (path as NSString).lastPathComponent
    }
}

actor ArchiveService {
    func listContents(at path: String) async throws -> [ArchiveEntry] {
        let ext = (path as NSString).pathExtension.lowercased()

        switch ext {
        case "zip":
            return try await listZip(path)
        case "tar", "tgz", "tar.gz", "tar.bz2", "tar.xz":
            return try await listTar(path)
        case "rar":
            return try await listRar(path)
        case "7z":
            return try await list7z(path)
        default:
            throw ArchiveError.unsupportedFormat(ext)
        }
    }

    func extract(at path: String, to destination: String) async throws {
        let ext = (path as NSString).pathExtension.lowercased()
        let fm = FileManager.default

        try? fm.createDirectory(atPath: destination, withIntermediateDirectories: true)

        switch ext {
        case "zip":
            try await runProcess("/usr/bin/ditto", args: ["-xk", path, destination])
        case "tar":
            try await runProcess("/usr/bin/tar", args: ["xf", path, "-C", destination])
        case "tgz", "tar.gz":
            try await runProcess("/usr/bin/tar", args: ["xzf", path, "-C", destination])
        case "tar.bz2":
            try await runProcess("/usr/bin/tar", args: ["xjf", path, "-C", destination])
        case "tar.xz":
            try await runProcess("/usr/bin/tar", args: ["xJf", path, "-C", destination])
        case "rar":
            try await runProcess("/usr/bin/unrar", args: ["x", "-o+", path, destination + "/"])
        case "7z":
            try await runProcess("/usr/bin/7z", args: ["x", "-o" + destination, path])
        default:
            throw ArchiveError.unsupportedFormat(ext)
        }
    }

    private func listZip(_ path: String) async throws -> [ArchiveEntry] {
        let output = try await runProcess("/usr/bin/ditto", args: ["--list", path])
        var entries: [ArchiveEntry] = []

        for line in output.components(separatedBy: "\n") where !line.isEmpty {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let isDir = trimmed.hasSuffix("/")
            let name = (trimmed as NSString).lastPathComponent
            let fullPath = trimmed.hasPrefix("/") ? trimmed : ((path as NSString).deletingLastPathComponent as NSString).appendingPathComponent(trimmed)

            entries.append(ArchiveEntry(
                path: fullPath,
                name: name,
                size: 0,
                compressedSize: nil,
                isDirectory: isDir,
                modificationDate: nil
            ))
        }
        return entries
    }

    private func listTar(_ path: String) async throws -> [ArchiveEntry] {
        let output = try await runProcess("/usr/bin/tar", args: ["tf", path])
        var entries: [ArchiveEntry] = []

        for line in output.components(separatedBy: "\n") where !line.isEmpty {
            let isDir = line.hasSuffix("/")
            let name = (line as NSString).lastPathComponent

            entries.append(ArchiveEntry(
                path: line,
                name: name,
                size: 0,
                compressedSize: nil,
                isDirectory: isDir,
                modificationDate: nil
            ))
        }
        return entries
    }

    private func listRar(_ path: String) async throws -> [ArchiveEntry] {
        let output = try await runProcess("/usr/bin/unrar", args: ["lt", path])
        var entries: [ArchiveEntry] = []
        var currentName = ""
        var currentSize: Int64 = 0
        var currentPacked: Int64 = 0
        var currentIsDir = false

        for line in output.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("Name:") {
                if !currentName.isEmpty {
                    entries.append(ArchiveEntry(path: currentName, name: (currentName as NSString).lastPathComponent, size: currentSize, compressedSize: currentPacked, isDirectory: currentIsDir, modificationDate: nil))
                }
                currentName = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                currentIsDir = currentName.hasSuffix("/")
                currentSize = 0
                currentPacked = 0
            } else if trimmed.hasPrefix("Size:") {
                currentSize = Int64(trimmed.replacingOccurrences(of: "Size:", with: "").trimmingCharacters(in: .whitespaces)) ?? 0
            } else if trimmed.hasPrefix("Packed size:") {
                currentPacked = Int64(trimmed.replacingOccurrences(of: "Packed size:", with: "").trimmingCharacters(in: .whitespaces)) ?? 0
            }
        }
        if !currentName.isEmpty {
            entries.append(ArchiveEntry(path: currentName, name: (currentName as NSString).lastPathComponent, size: currentSize, compressedSize: currentPacked, isDirectory: currentIsDir, modificationDate: nil))
        }
        return entries
    }

    private func list7z(_ path: String) async throws -> [ArchiveEntry] {
        let output = try await runProcess("/usr/bin/7z", args: ["l", path])
        var entries: [ArchiveEntry] = []
        var inBody = false

        for line in output.components(separatedBy: "\n") {
            if line.contains("---") { inBody = true; continue }
            guard inBody, !line.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 5 else { continue }
            let name = String(parts.last!)
            let size = Int64(parts[parts.count - 3]) ?? 0
            let isDir = name.hasSuffix("/")

            entries.append(ArchiveEntry(path: name, name: (name as NSString).lastPathComponent, size: size, compressedSize: nil, isDirectory: isDir, modificationDate: nil))
        }
        return entries
    }

    private func runProcess(_ path: String, args: [String]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: path)
            process.arguments = args

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice

            process.terminationHandler = { _ in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                if process.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    continuation.resume(throwing: ArchiveError.extractionFailed("Exit code \(process.terminationStatus)"))
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

enum ArchiveError: Error, LocalizedError {
    case unsupportedFormat(String)
    case extractionFailed(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let ext): return "Unsupported archive format: \(ext)"
        case .extractionFailed(let msg): return "Extraction failed: \(msg)"
        }
    }
}
