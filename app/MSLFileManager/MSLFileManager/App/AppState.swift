import Foundation
import SwiftUI

@Observable
@MainActor
final class AppState {
    var selectedViewMode: ViewMode = .list
    var currentPath: URL = .homeDirectory
    var selectedItems: Set<String> = []
    var vmStatus: VMStatus = .unknown
    var sidebarSelection: SidebarItem? = .favorites
    var isPreviewVisible: Bool = true
    var isAIAssistantVisible: Bool = false
    var isLoading: Bool = false

    let vmLifecycle: VMLifecycleService
    let vmCommand: VMCommandService
    let diskMonitor: DiskMonitor
    let fileSystem: UnifiedFileService
    let ntfsMountService: NTFSMountService

    init() {
        self.vmLifecycle = VMLifecycleService()
        self.vmCommand = VMCommandService()
        self.diskMonitor = DiskMonitor()
        self.fileSystem = UnifiedFileService()
        self.ntfsMountService = NTFSMountService()
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
