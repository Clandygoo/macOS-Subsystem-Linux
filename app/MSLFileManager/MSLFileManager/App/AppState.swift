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

    @Published var tabs: [FileTab] = [FileTab(title: "Home", path: NSHomeDirectory())]
    @Published var activeTabID: UUID?

    lazy var vmLifecycle = VMLifecycleService()
    lazy var vmCommand = VMCommandService()
    lazy var diskMonitor = DiskMonitor()
    lazy var fileSystem = UnifiedFileService()
    lazy var ntfsMountService = NTFSMountService()

    init() {
        activeTabID = tabs.first?.id
    }

    var activeTab: FileTab? {
        tabs.first { $0.id == activeTabID }
    }

    func addTab(path: String = NSHomeDirectory(), title: String = "New Tab", isRemote: Bool = false) {
        let tab = FileTab(title: title, path: path, isRemote: isRemote)
        tabs.append(tab)
        activeTabID = tab.id
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
