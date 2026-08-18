import Foundation

struct FileTab: Identifiable, Equatable {
    let id = UUID()
    var title: String = "Home"
    var path: String = "/"
    var isRemote: Bool = false
    var selectedItems: Set<String> = []
}
