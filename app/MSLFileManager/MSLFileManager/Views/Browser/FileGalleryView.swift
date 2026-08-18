import SwiftUI

struct FileGalleryView: View {
    @EnvironmentObject private var state: AppState
    @ObservedObject var viewModel: BrowserViewModel
    @State private var selectedIndex: Int = 0

    var selectedItem: FileItem? {
        guard selectedIndex >= 0, selectedIndex < viewModel.items.count else { return nil }
        return viewModel.items[selectedIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                if let item = selectedItem {
                    VStack(spacing: 16) {
                        if item.isDirectory {
                            Image(nsImage: item.icon)
                                .resizable()
                                .frame(width: 192, height: 192)
                        } else {
                            thumbnailOrIcon(item: item, size: min(geo.size.width - 40, geo.size.height - 80))
                        }

                        VStack(spacing: 4) {
                            Text(item.name)
                                .font(.title3)
                                .fontWeight(.medium)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)

                            if item.isDirectory {
                                Text("Folder")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("\(item.displaySize)  •  \(item.displayDate)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ContentUnavailableView(
                        "No Selection",
                        systemImage: "photo",
                        description: Text("Select a file to preview")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }

            Divider()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(viewModel.items) { item in
                        let index = viewModel.items.firstIndex(where: { $0.id == item.id }) ?? 0
                        thumbnailStripItem(item: item, isSelected: index == selectedIndex)
                            .onTapGesture {
                                selectedIndex = index
                                state.selectedItems = [item.id]
                            }
                            .onTapGesture(count: 2) {
                                openItem(item)
                            }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
            .frame(height: 72)
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .onChange(of: viewModel.items.count) { _, _ in
            selectedIndex = 0
            if let first = viewModel.items.first {
                state.selectedItems = [first.id]
            }
        }
        .onKeyPress(.upArrow) {
            if selectedIndex > 0 {
                selectedIndex -= 1
                state.selectedItems = [viewModel.items[selectedIndex].id]
            }
            return .handled
        }
        .onKeyPress(.downArrow) {
            if selectedIndex < viewModel.items.count - 1 {
                selectedIndex += 1
                state.selectedItems = [viewModel.items[selectedIndex].id]
            }
            return .handled
        }
    }

    @ViewBuilder
    private func thumbnailOrIcon(item: FileItem, size: CGFloat) -> some View {
        if let url = item.url, isImage(item) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: size, height: size)
                case .failure:
                    placeholderIcon(item: item, size: size)
                default:
                    ProgressView()
                        .frame(width: size, height: size)
                }
            }
        } else {
            placeholderIcon(item: item, size: size)
        }
    }

    private func placeholderIcon(item: FileItem, size: CGFloat) -> some View {
        Image(nsImage: item.icon)
            .resizable()
            .frame(width: min(size, 192), height: min(size, 192))
    }

    @ViewBuilder
    private func thumbnailStripItem(item: FileItem, isSelected: Bool) -> some View {
        VStack(spacing: 2) {
            if let url = item.url, isImage(item) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        Image(nsImage: item.icon)
                            .resizable()
                    }
                }
                .frame(width: 52, height: 52)
                .clipped()
                .cornerRadius(4)
            } else {
                Image(nsImage: item.icon)
                    .resizable()
                    .frame(width: 52, height: 52)
                    .cornerRadius(4)
            }

            Text(item.name)
                .font(.system(size: 8))
                .lineLimit(1)
                .frame(width: 56)
        }
        .padding(2)
        .background(isSelected ? Color.accentColor.opacity(0.3) : Color.clear)
        .cornerRadius(6)
    }

    private func isImage(_ item: FileItem) -> Bool {
        let ext = ((item.url?.path ?? "") as NSString).pathExtension.lowercased()
        return ["jpg", "jpeg", "png", "gif", "heic", "heif", "webp", "tiff", "bmp", "svg"].contains(ext)
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
}
