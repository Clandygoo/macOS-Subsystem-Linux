import SwiftUI

struct FileColumnView: View {
    @EnvironmentObject private var state: AppState
    @ObservedObject var viewModel: BrowserViewModel
    @State private var columns: [[FileItem]] = []
    @State private var selectedPerColumn: [Int: String?] = [:]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(columns.enumerated()), id: \.offset) { colIndex, items in
                VStack(spacing: 0) {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(items) { item in
                                FileColumnRow(
                                    item: item,
                                    isSelected: selectedPerColumn[colIndex] == nil
                                        ? false
                                        : selectedPerColumn[colIndex]! == item.id,
                                    isExpanded: colIndex < columns.count - 1 && selectedPerColumn[colIndex] ?? "" == item.id
                                )
                                .onTapGesture {
                                    selectItem(item, at: colIndex)
                                }
                                .onTapGesture(count: 2) {
                                    if item.isDirectory {
                                        expandToItem(item, at: colIndex)
                                    }
                                }
                            }
                        }
                    }
                    .frame(minWidth: 180, idealWidth: 220, maxWidth: 300)

                    if colIndex < columns.count - 1 {
                        Divider()
                    }
                }
            }

            if !columns.isEmpty {
                VStack(spacing: 0) {
                    if let selCol = lastSelectedColumnIndex(), let item = selectedItem(in: selCol) {
                        ScrollView {
                            VStack(spacing: 12) {
                                Image(nsImage: item.icon)
                                    .resizable()
                                    .frame(width: 128, height: 128)

                                Text(item.name)
                                    .font(.headline)
                                    .multilineTextAlignment(.center)

                                if item.isDirectory {
                                    Text("Folder")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text(item.displaySize)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Text(item.displayDate)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                        }
                    } else {
                        ContentUnavailableView(
                            "No Selection",
                            systemImage: "sidebar.right",
                            description: Text("Select a file to preview")
                        )
                    }
                }
                .frame(width: 200)
                .background(Color(nsColor: .controlBackgroundColor))
                Divider()
            }
        }
        .task {
            if columns.isEmpty {
                await loadColumn(at: viewModel.currentPath, index: 0)
            }
        }
        .onChange(of: viewModel.currentPath) { _, newPath in
            columns = []
            selectedPerColumn = [:]
            Task {
                await loadColumn(at: newPath, index: 0)
            }
        }
    }

    private func selectItem(_ item: FileItem, at colIndex: Int) {
        selectedPerColumn[colIndex] = item.id
        if item.isDirectory {
            Task {
                await loadColumn(at: item.remotePath ?? item.url?.path ?? "", index: colIndex + 1)
            }
        }
    }

    private func expandToItem(_ item: FileItem, at colIndex: Int) {
        selectItem(item, at: colIndex)
    }

    private func loadColumn(at path: String, index: Int) async {
        let items: [FileItem]
        if viewModel.isRemotePath(path) {
            items = (try? await UnifiedFileService().listRemoteContents(at: path)) ?? []
        } else {
            items = (try? await UnifiedFileService().listLocalContents(at: URL(fileURLWithPath: path))) ?? []
        }
        let sorted = sortItems(items)
        if index < columns.count {
            columns = Array(columns.prefix(index))
        }
        columns.append(sorted)
        selectedPerColumn[index] = nil
    }

    private func lastSelectedColumnIndex() -> Int? {
        for i in stride(from: columns.count - 1, through: 0, by: -1) {
            if let sel = selectedPerColumn[i], sel != nil {
                return i
            }
        }
        return nil
    }

    private func selectedItem(in colIndex: Int) -> FileItem? {
        guard let selId = selectedPerColumn[colIndex] else { return nil }
        return columns[colIndex].first { $0.id == selId }
    }

    private func sortItems(_ items: [FileItem]) -> [FileItem] {
        items.sorted { a, b in
            if a.isDirectory != b.isDirectory { return a.isDirectory }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }
}

struct FileColumnRow: View {
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
