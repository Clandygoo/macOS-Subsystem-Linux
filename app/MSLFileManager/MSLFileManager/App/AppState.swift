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

    lazy var vmLifecycle = VMLifecycleService()
    lazy var vmCommand = VMCommandService()
    lazy var diskMonitor = DiskMonitor()
    lazy var fileSystem = UnifiedFileService()
    lazy var ntfsMountService = NTFSMountService()

    init() {}
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
