import Foundation
import AppKit

enum ViewMode: String, CaseIterable, Identifiable {
    case list
    case icon
    case column
    case gallery

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .list: return "List"
        case .icon: return "Icons"
        case .column: return "Columns"
        case .gallery: return "Gallery"
        }
    }

    var iconName: String {
        switch self {
        case .list: return "list.bullet"
        case .icon: return "square.grid.2x2"
        case .column: return "columns.3"
        case .gallery: return "rectangle.on.rectangle"
        }
    }
}
