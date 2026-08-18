import Foundation
import AppKit

final class BrowserViewModel: ObservableObject {
    @Published var items: [FileItem] = []
    @Published var isLoading: Bool = false
    @Published var sortOption: SortOption = .name
    @Published var sortAscending: Bool = true
    @Published var showHiddenFiles: Bool = false
    @Published var currentPath: String = "/"
    @Published var navigationHistory: [String] = []
    @Published var navigationIndex: Int = -1

    private let fileSystem = UnifiedFileService()
    private var currentTask: Task<Void, Never>?
    private var isNavigatingBackForward = false

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

            if !isNavigatingBackForward {
                if navigationHistory.isEmpty || navigationHistory[navigationIndex] != path {
                    navigationHistory = Array(navigationHistory.prefix(navigationIndex + 1))
                    navigationHistory.append(path)
                    navigationIndex = navigationHistory.count - 1
                }
            }
            isNavigatingBackForward = false
        } catch {
            items = []
        }
    }

    func navigateTo(_ path: String, isRemote: Bool = false) {
        isNavigatingBackForward = false
        Task {
            await loadContents(at: path, isRemote: isRemote)
        }
    }

    func goBack() {
        guard canGoBack else { return }
        navigationIndex -= 1
        let path = navigationHistory[navigationIndex]
        isNavigatingBackForward = true
        Task {
            let isRemote = isRemotePath(path)
            await loadContents(at: path, isRemote: isRemote)
        }
    }

    func goForward() {
        guard canGoForward else { return }
        navigationIndex += 1
        let path = navigationHistory[navigationIndex]
        isNavigatingBackForward = true
        Task {
            let isRemote = isRemotePath(path)
            await loadContents(at: path, isRemote: isRemote)
        }
    }

    func goToParent() {
        let parent = (currentPath as NSString).deletingLastPathComponent
        guard parent != currentPath else { return }
        isNavigatingBackForward = false
        Task {
            await loadContents(at: parent, isRemote: isRemotePath(parent))
        }
    }

    func refresh() {
        let path = currentPath
        let isRemote = isRemotePath(path)
        isNavigatingBackForward = true
        Task {
            await loadContents(at: path, isRemote: isRemote)
        }
    }

    func isRemotePath(_ path: String) -> Bool {
        return path.hasPrefix("/mnt/") || path.hasPrefix("/Volumes/Linux")
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
