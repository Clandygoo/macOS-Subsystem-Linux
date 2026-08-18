import Foundation

enum SidebarItem: Identifiable, Hashable {
    case favorites
    case recent
    case applications
    case desktop
    case documents
    case downloads
    case home
    case vm
    case vmDisk(String)
    case mount(String)

    var id: String {
        switch self {
        case .favorites: return "favorites"
        case .recent: return "recent"
        case .applications: return "applications"
        case .desktop: return "desktop"
        case .documents: return "documents"
        case .downloads: return "downloads"
        case .home: return "home"
        case .vm: return "vm"
        case .vmDisk(let id): return "vmDisk-\(id)"
        case .mount(let id): return "mount-\(id)"
        }
    }

    var displayName: String {
        switch self {
        case .favorites: return "Favorites"
        case .recent: return "Recent"
        case .applications: return "Applications"
        case .desktop: return "Desktop"
        case .documents: return "Documents"
        case .downloads: return "Downloads"
        case .home: return "Home"
        case .vm: return "Linux VM"
        case .vmDisk(let id): return "Disk \(id)"
        case .mount(let id): return "Mount \(id)"
        }
    }

    var iconName: String {
        switch self {
        case .favorites: return "star.fill"
        case .recent: return "clock.fill"
        case .applications: return "app.fill"
        case .desktop: return "desktopcomputer"
        case .documents: return "doc.fill"
        case .downloads: return "arrow.down.circle.fill"
        case .home: return "house.fill"
        case .vm: return "terminal.fill"
        case .vmDisk: return "externaldrive.fill"
        case .mount: return "externaldrive.connected.to.line.below"
        }
    }

    var localURL: URL? {
        switch self {
        case .desktop: return FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
        case .documents: return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        case .downloads: return FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        case .home: return FileManager.default.homeDirectoryForCurrentUser
        case .applications: return URL(fileURLWithPath: "/Applications")
        default: return nil
        }
    }

    var isRemote: Bool {
        switch self {
        case .vm, .vmDisk, .mount: return true
        default: return false
        }
    }
}
