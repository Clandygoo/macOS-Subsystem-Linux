import SwiftUI

struct ArchivePreviewView: View {
    let archivePath: String
    @State private var entries: [ArchiveEntry] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var selectedEntries: Set<ArchiveEntry.ID> = []
    @State private var extractedPath: String?
    @State private var isExtracting = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "archivebox")
                    .foregroundStyle(.orange)
                Text((archivePath as NSString).lastPathComponent)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()

                Button("Extract All") {
                    extractAll()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isExtracting)

                if !selectedEntries.isEmpty {
                    Button("Extract Selected (\(selectedEntries.count))") {
                        extractSelected()
                    }
                    .buttonStyle(.bordered)
                    .disabled(isExtracting)
                }
            }
            .padding()

            Divider()

            if isLoading {
                ProgressView("Loading archive...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error {
                ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
            } else if entries.isEmpty {
                ContentUnavailableView("No Archive Contents", systemImage: "archivebox")
            } else {
                List(entries, selection: $selectedEntries) { entry in
                    HStack(spacing: 8) {
                        Image(systemName: entry.isDirectory ? "folder.fill" : fileIcon(for: entry.name))
                            .foregroundStyle(entry.isDirectory ? .blue : .secondary)
                            .frame(width: 16)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.name)
                                .lineLimit(1)

                            if !entry.isDirectory {
                                Text(formatSize(entry.size))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        if entry.isDirectory {
                            Image(systemName: "folder")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                    .tag(entry.id)
                }
            }
        }
        .task {
            await loadArchive()
        }
    }

    private func loadArchive() async {
        isLoading = true
        error = nil
        let service = ArchiveService()
        do {
            entries = try await service.listContents(at: archivePath)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func extractAll() {
        isExtracting = true
        let dest = (archivePath as NSString).deletingLastPathComponent
        Task {
            let service = ArchiveService()
            do {
                try await service.extract(at: archivePath, to: dest)
                extractedPath = dest
            } catch {
                self.error = error.localizedDescription
            }
            isExtracting = false
        }
    }

    private func extractSelected() {
        isExtracting = true
        let dest = (archivePath as NSString).deletingLastPathComponent
        Task {
            let service = ArchiveService()
            do {
                try await service.extract(at: archivePath, to: dest)
                extractedPath = dest
            } catch {
                self.error = error.localizedDescription
            }
            isExtracting = false
        }
    }

    private func fileIcon(for name: String) -> String {
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "swift", "py", "js", "ts", "java", "c", "cpp", "h": return "doc.text"
        case "jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic": return "photo"
        case "mp4", "mov", "avi", "mkv", "webm": return "film"
        case "mp3", "wav", "aac", "flac", "m4a": return "music.note"
        case "pdf": return "doc.richtext"
        case "zip", "tar", "gz", "bz2", "xz", "rar", "7z": return "archivebox"
        case "app": return "app.fill"
        default: return "doc"
        }
    }

    private func formatSize(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
