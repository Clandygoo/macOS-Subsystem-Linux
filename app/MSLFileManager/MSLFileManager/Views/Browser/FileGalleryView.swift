import SwiftUI

struct FileGalleryView: View {
    @EnvironmentObject private var state: AppState
    @ObservedObject var viewModel: BrowserViewModel

    private let columns = [
        GridItem(.adaptive(minimum: 140, maximum: 200), spacing: 20)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(viewModel.items) { item in
                    FileGalleryItemView(item: item, isSelected: state.selectedItems.contains(item.id))
                        .onTapGesture {
                            state.selectedItems = [item.id]
                        }
                        .onTapGesture(count: 2) {
                            openItem(item)
                        }
                        .contextMenu {
                            Button(L10n.t("context.open")) { openItem(item) }

                            if isArchive(item) {
                                Divider()
                                Button(L10n.t("context.extract_here")) { extractHere(item) }
                            }

                            if item.name.hasSuffix(".app") {
                                Divider()
                                Button(L10n.t("context.view_contents")) { viewPackageContents(item) }
                            }

                            Divider()
                            Button(L10n.t("context.copy")) { copyItem(item) }
                            Button(L10n.t("context.move_to_trash")) { deleteItem(item) }
                        }
                        .onDrag {
                            if let url = item.url {
                                return NSItemProvider(object: url as NSURL)
                            }
                            return NSItemProvider()
                        }
                }
            }
            .padding()
        }
        .onDrop(of: [.fileURL], delegate: GalleryDropDelegate(viewModel: viewModel))
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

struct FileGalleryItemView: View {
    let item: FileItem
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            if item.isDirectory {
                Image(nsImage: item.icon)
                    .resizable()
                    .frame(width: 80, height: 80)
            } else {
                thumbnailView
                    .frame(width: 140, height: 100)
                    .clipped()
                    .cornerRadius(6)
            }

            Text(item.name)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 140)

            if !item.isDirectory {
                Text(item.displaySize)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(10)
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let url = item.url, isImage {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    placeholder
                default:
                    ProgressView()
                        .frame(width: 140, height: 100)
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Image(nsImage: item.icon)
            .resizable()
            .frame(width: 64, height: 64)
            .frame(width: 140, height: 100)
            .background(Color(nsColor: .controlBackgroundColor))
    }

    private var isImage: Bool {
        let ext = ((item.url?.path ?? "") as NSString).pathExtension.lowercased()
        return ["jpg", "jpeg", "png", "gif", "heic", "heif", "webp", "tiff", "bmp", "svg"].contains(ext)
    }
}

struct GalleryDropDelegate: DropDelegate {
    let viewModel: BrowserViewModel

    func performDrop(info: DropInfo) -> Bool {
        guard let providers = info.itemProviders(for: [.fileURL]).first else { return false }
        providers.loadObject(ofClass: NSURL.self) { url, _ in
            if let url = url as? URL {
                let dest = (viewModel.currentPath as NSString).appendingPathComponent(url.lastPathComponent)
                if !FileManager.default.fileExists(atPath: dest) {
                    try? FileManager.default.copyItem(at: url, to: URL(fileURLWithPath: dest))
                }
                DispatchQueue.main.async { viewModel.refresh() }
            }
        }
        return true
    }
}
