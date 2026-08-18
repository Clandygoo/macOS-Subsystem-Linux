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
                }
            }
            .padding()
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
