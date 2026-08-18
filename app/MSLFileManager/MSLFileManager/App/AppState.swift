import Foundation
import SwiftUI

final class AppState: ObservableObject {
    @Published var selectedViewMode: ViewMode = .list
    @Published var currentPath: URL = .homeDirectory
    @Published var selectedItems: Set<String> = []
    @Published var vmStatus: VMStatus = .unknown
    @Published var sidebarSelection: SidebarItem? = .favorites
    @Published var isPreviewVisible: Bool = true
    @Published var isAIAssistantVisible: Bool = false
    @Published var isLoading: Bool = false
    @Published var isVMStarting: Bool = true
    @AppStorage("language") var language: String = Locale.current.language.languageCode?.identifier == "zh" ? "zh" : "en"

    @Published var tabs: [FileTab] = []
    @Published var activeTabID: UUID?

    lazy var vmLifecycle = VMLifecycleService()
    lazy var vmCommand = VMCommandService()
    lazy var diskMonitor = DiskMonitor()
    lazy var fileSystem = UnifiedFileService()
    lazy var ntfsMountService = NTFSMountService()

    init() {
        let home = NSHomeDirectory()
        let tab = FileTab(title: Self.folderName(for: home), path: home)
        tabs = [tab]
        activeTabID = tab.id
    }

    static func folderName(for path: String) -> String {
        let url = URL(fileURLWithPath: path)
        let name = url.lastPathComponent
        return name.isEmpty ? path : name
    }

    var activeTab: FileTab? {
        tabs.first { $0.id == activeTabID }
    }

    func addTab(path: String = NSHomeDirectory(), title: String? = nil, isRemote: Bool = false) {
        let tabTitle = title ?? Self.folderName(for: path)
        let tab = FileTab(title: tabTitle, path: path, isRemote: isRemote)
        tabs.append(tab)
        activeTabID = tab.id
    }

    func updateTabTitle(id: UUID, title: String) {
        guard let idx = tabs.firstIndex(where: { $0.id == id }) else { return }
        tabs[idx].title = title
    }

    func closeTab(id: UUID) {
        guard tabs.count > 1 else { return }
        tabs.removeAll { $0.id == id }
        if activeTabID == id {
            activeTabID = tabs.last?.id
        }
    }

    func switchTab(to id: UUID) {
        activeTabID = id
    }
}

enum VMStatus: Sendable {
    case unknown
    case starting
    case running
    case stopped
    case error(String)

    var displayName: String {
        switch self {
        case .unknown: return "Unknown"
        case .starting: return "Starting..."
        case .running: return "Running"
        case .stopped: return "Stopped"
        case .error(let msg): return "Error: \(msg)"
        }
    }

    var isRunning: Bool {
        if case .running = self { return true }
        return false
    }
}
