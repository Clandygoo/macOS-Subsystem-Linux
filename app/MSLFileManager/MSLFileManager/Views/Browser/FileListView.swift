import SwiftUI

struct FileListView: View {
    @Environment(AppState.self) private var state
    @Bindable var viewModel: BrowserViewModel

    var body: some View {
        Table(viewModel.items, selection: Binding(
            get: { state.selectedItems },
            set: { state.selectedItems = $0 }
        )) {
            TableColumn("Name") { item in
                HStack(spacing: 8) {
                    Image(nsImage: item.icon)
                        .resizable()
                        .frame(width: 16, height: 16)
                    Text(item.name)
                        .lineLimit(1)
                }
            }
            .width(min: 150, ideal: 250)

            TableColumn("Size") { item in
                Text(item.isDirectory ? "--" : item.displaySize)
                    .foregroundStyle(.secondary)
            }
            .width(min: 80, ideal: 100)

            TableColumn("Date Modified") { item in
                Text(item.displayDate)
                    .foregroundStyle(.secondary)
            }
            .width(min: 120, ideal: 150)

            TableColumn("Kind") { item in
                Text(item.isDirectory ? "Folder" : item.typeIdentifier.components(separatedBy: ".").last ?? "")
                    .foregroundStyle(.secondary)
            }
            .width(min: 100, ideal: 120)
        }
        .contextMenu(forSelectionType: String.self) { selection in
            if let itemId = selection.first, let item = viewModel.items.first(where: { $0.id == itemId }) {
                Button("Open") {
                    openItem(item)
                }
                Divider()
                Button("Copy") {
                    copyItem(item)
                }
                Divider()
                Button("Delete") {
                    deleteItem(item)
                }
            }
        } primaryAction: { selection in
            if let itemId = selection.first, let item = viewModel.items.first(where: { $0.id == itemId }) {
                openItem(item)
            }
        }
        .onChange(of: state.selectedItems) { _, newValue in
            if let _ = newValue.first {
                state.selectedItems = newValue
            }
        }
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
