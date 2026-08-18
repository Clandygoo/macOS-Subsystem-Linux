import SwiftUI

struct FileColumnView: View {
    @Environment(AppState.self) private var state
    @Bindable var viewModel: BrowserViewModel
    @State private var columnPaths: [String] = []

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(columnPaths.enumerated()), id: \.offset) { index, path in
                VStack(spacing: 0) {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(itemsForPath(path)) { item in
                                FileColumnRowView(
                                    item: item,
                                    isSelected: state.selectedItems.contains(item.id),
                                    isExpanded: index < columnPaths.count - 1 && columnPaths[index + 1] == (item.remotePath ?? item.url?.path ?? "")
                                )
                                .onTapGesture {
                                    state.selectedItems = [item.id]
                                }
                                .onTapGesture(count: 2) {
                                    if item.isDirectory {
                                        expandColumn(at: index + 1, path: item.remotePath ?? item.url?.path ?? "")
                                    }
                                }
                            }
                        }
                    }
                    .frame(width: 200)

                    if index < columnPaths.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .task {
            if columnPaths.isEmpty {
                columnPaths = [viewModel.currentPath]
            }
        }
    }

    private func itemsForPath(_ path: String) -> [FileItem] {
        viewModel.items.filter { item in
            let itemPath = item.remotePath ?? item.url?.path ?? ""
            let parent = (itemPath as NSString).deletingLastPathComponent
            return parent == path
        }
    }

    private func expandColumn(at index: Int, path: String) {
        if index < columnPaths.count {
            columnPaths = Array(columnPaths.prefix(index))
        }
        columnPaths.append(path)
    }
}

struct FileColumnRowView: View {
    let item: FileItem
    let isSelected: Bool
    let isExpanded: Bool

    var body: some View {
        HStack {
            Image(nsImage: item.icon)
                .resizable()
                .frame(width: 16, height: 16)

            Text(item.name)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            if item.isDirectory {
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
    }
}
