import Foundation
import AppKit

@Observable
@MainActor
final class BrowserViewModel {
    var items: [FileItem] = []
    var isLoading: Bool = false
    var sortOption: SortOption = .name
    var sortAscending: Bool = true
    var showHiddenFiles: Bool = false
    var currentPath: String = "/"
    var navigationHistory: [String] = []
    var navigationIndex: Int = -1

    private let fileSystem = UnifiedFileService()
    private var currentTask: Task<Void, Never>?

    var canGoBack: Bool { navigationIndex > 0 }
    var canGoForward: Bool { navigationIndex < navigationHistory.count - 1 }

    func loadContents(at path: String, isRemote: Bool = false) async {
        currentTask?.cancel()
        isLoading = true
        defer { isLoading = false }

        do {
            let newItems: [FileItem]
            if isRemote {
                newItems = try await fileSystem.listRemoteContents(at: path)
            } else {
                let url = URL(fileURLWithPath: path)
                newItems = try await fileSystem.listLocalContents(at: url)
            }

            items = sortItems(newItems.filter { showHiddenFiles || !$0.isHidden })
            currentPath = path

            if navigationHistory.isEmpty || navigationHistory[navigationIndex] != path {
                navigationHistory = Array(navigationHistory.prefix(navigationIndex + 1))
                navigationHistory.append(path)
                navigationIndex = navigationHistory.count - 1
            }
        } catch {
            items = []
        }
    }

    func goBack() {
        guard canGoBack else { return }
        navigationIndex -= 1
        let path = navigationHistory[navigationIndex]
        Task {
            let isRemote = path.hasPrefix("/mnt/") || path.hasPrefix("/Volumes/")
            await loadContents(at: path, isRemote: isRemote)
        }
    }

    func goForward() {
        guard canGoForward else { return }
        navigationIndex += 1
        let path = navigationHistory[navigationIndex]
        Task {
            let isRemote = path.hasPrefix("/mnt/") || path.hasPrefix("/Volumes/")
            await loadContents(at: path, isRemote: isRemote)
        }
    }

    func goToParent() {
        let parent = (currentPath as NSString).deletingLastPathComponent
        Task {
            await loadContents(at: parent, isRemote: currentPath.hasPrefix("/mnt/"))
        }
    }

    func refresh() {
        let path = currentPath
        Task {
            let isRemote = path.hasPrefix("/mnt/") || path.hasPrefix("/Volumes/")
            await loadContents(at: path, isRemote: isRemote)
        }
    }

    private func sortItems(_ items: [FileItem]) -> [FileItem] {
        var sorted = items

        sorted.sort { a, b in
            if a.isDirectory != b.isDirectory {
                return a.isDirectory
            }

            let result: Bool
            switch sortOption {
            case .name:
                result = a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            case .size:
                result = a.size < b.size
            case .date:
                result = a.modificationDate < b.modificationDate
            case .kind:
                result = a.typeIdentifier.localizedCaseInsensitiveCompare(b.typeIdentifier) == .orderedAscending
            }

            return sortAscending ? result : !result
        }

        return sorted
    }

    func toggleSort(for option: SortOption) {
        if sortOption == option {
            sortAscending.toggle()
        } else {
            sortOption = option
            sortAscending = true
        }
        items = sortItems(items)
    }
}
