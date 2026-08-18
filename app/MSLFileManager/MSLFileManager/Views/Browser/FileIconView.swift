import SwiftUI

struct FileIconView: View {
    @EnvironmentObject private var state: AppState
    @ObservedObject var viewModel: BrowserViewModel

    private let columns = [
        GridItem(.adaptive(minimum: 80, maximum: 120), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.items) { item in
                    FileIconItemView(item: item, isSelected: state.selectedItems.contains(item.id))
                        .onTapGesture {
                            state.selectedItems = [item.id]
                        }
                        .onTapGesture(count: 2) {
                            openItem(item)
                        }
                        .contextMenu {
                            Button(L10n.t("context.open")) { openItem(item) }
                            Divider()
                            Button(L10n.t("context.copy")) { copyItem(item) }
                            Divider()
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
        .onDrop(of: [.fileURL], delegate: IconGridDropDelegate(viewModel: viewModel))
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

struct FileIconItemView: View {
    let item: FileItem
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(nsImage: item.icon)
                .resizable()
                .frame(width: 48, height: 48)

            Text(item.name)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 80)
        }
        .padding(8)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(8)
    }
}

struct IconGridDropDelegate: DropDelegate {
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
