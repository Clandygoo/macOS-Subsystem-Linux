import SwiftUI

struct FileListView: View {
    @EnvironmentObject private var state: AppState
    @ObservedObject var viewModel: BrowserViewModel
    @State private var archivePath: String?

    var body: some View {
        Table(viewModel.items, selection: Binding(
            get: { state.selectedItems },
            set: { state.selectedItems = $0 }
        )) {
            TableColumn(L10n.t("column.name")) { item in
                HStack(spacing: 8) {
                    Image(nsImage: item.icon)
                        .resizable()
                        .frame(width: 16, height: 16)
                    Text(item.name)
                        .lineLimit(1)
                }
            }
            .width(min: 150, ideal: 250)

            TableColumn(L10n.t("column.size")) { item in
                Text(item.isDirectory ? "--" : item.displaySize)
                    .foregroundStyle(.secondary)
            }
            .width(min: 80, ideal: 100)

            TableColumn(L10n.t("column.date")) { item in
                Text(item.displayDate)
                    .foregroundStyle(.secondary)
            }
            .width(min: 120, ideal: 150)

            TableColumn(L10n.t("column.kind")) { item in
                Text(item.isDirectory ? L10n.t("browser.folder") : item.typeIdentifier.components(separatedBy: ".").last ?? "")
                    .foregroundStyle(.secondary)
            }
            .width(min: 100, ideal: 120)
        }
        .contextMenu(forSelectionType: String.self) { selection in
            if let itemId = selection.first, let item = viewModel.items.first(where: { $0.id == itemId }) {
                Button(L10n.t("context.open")) { openItem(item) }

                if isArchive(item) {
                    Divider()
                    Button(L10n.t("context.extract_here")) { extractHere(item) }
                    Button(L10n.t("context.extract_to")) { extractTo(item) }
                }

                if item.name.hasSuffix(".app") {
                    Divider()
                    Button(L10n.t("context.view_contents")) { viewPackageContents(item) }
                }

                Divider()
                Button(L10n.t("context.copy")) { copyItem(item) }
                Button(L10n.t("context.move_to_trash")) { deleteItem(item) }
            }
        } primaryAction: { selection in
            if let itemId = selection.first, let item = viewModel.items.first(where: { $0.id == itemId }) {
                openItem(item)
            }
        }
        .onDrop(of: [.fileURL], delegate: TableRowDropDelegate(viewModel: viewModel))
    }

    private func openItem(_ item: FileItem) {
        if item.isDirectory {
            Task {
                await viewModel.loadContents(at: item.remotePath ?? item.url?.path ?? "", isRemote: item.isRemote)
            }
        } else if let url = item.url {
            NSWorkspace.shared.open(url)
        }
    }

    private func isArchive(_ item: FileItem) -> Bool {
        let ext = ((item.url?.path ?? item.remotePath ?? "") as NSString).pathExtension.lowercased()
        return ["zip", "tar", "tgz", "tar.gz", "tar.bz2", "tar.xz", "rar", "7z"].contains(ext)
    }

    private func extractHere(_ item: FileItem) {
        guard let path = item.url?.path ?? item.remotePath else { return }
        let dest = (path as NSString).deletingLastPathComponent
        Task {
            let service = ArchiveService()
            try? await service.extract(at: path, to: dest)
            viewModel.refresh()
        }
    }

    private func extractTo(_ item: FileItem) {
        guard let path = item.url?.path ?? item.remotePath else { return }
        let panel = NSSavePanel()
        panel.title = L10n.t("archive.extract_to")
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = ((path as NSString).lastPathComponent as NSString).deletingPathExtension
        if panel.runModal() == .OK, let dest = panel.url {
            Task {
                let service = ArchiveService()
                try? await service.extract(at: path, to: dest.path)
                viewModel.refresh()
            }
        }
    }

    private func viewPackageContents(_ item: FileItem) {
        guard let url = item.url else { return }
        let contentsPath = url.appendingPathComponent("Contents")
        if FileManager.default.fileExists(atPath: contentsPath.path) {
            Task {
                await viewModel.loadContents(at: contentsPath.path, isRemote: false)
            }
        } else {
            NSWorkspace.shared.open(url)
        }
    }

    private func copyItem(_ item: FileItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        if let url = item.url {
            pasteboard.writeObjects([url as NSURL])
        }
    }

    private func deleteItem(_ item: FileItem) {
        guard let url = item.url else { return }
        try? FileManager.default.removeItem(at: url)
        viewModel.refresh()
    }
}

struct TableRowDropDelegate: DropDelegate {
    let viewModel: BrowserViewModel

    func performDrop(info: DropInfo) -> Bool {
        guard let items = info.itemProviders(for: [.fileURL]).first else { return false }
        items.loadObject(ofClass: NSURL.self) { url, _ in
            if let url = url as? URL {
                let dest = (viewModel.currentPath as NSString).appendingPathComponent(url.lastPathComponent)
                try? FileManager.default.copyItem(at: url, to: URL(fileURLWithPath: dest))
                DispatchQueue.main.async { viewModel.refresh() }
            }
        }
        return true
    }
}
