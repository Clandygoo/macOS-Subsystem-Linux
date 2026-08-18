import Foundation

enum SortOption: String, CaseIterable, Identifiable {
    case name
    case size
    case date
    case kind

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .name: return "Name"
        case .size: return "Size"
        case .date: return "Date Modified"
        case .kind: return "Kind"
        }
    }
}
