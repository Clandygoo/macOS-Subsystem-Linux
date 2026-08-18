import SwiftUI

struct FileBrowserView: View {
    @Environment(AppState.self) private var state
    @Bindable var viewModel: BrowserViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.items.isEmpty {
                ContentUnavailableView(
                    "No Items",
                    systemImage: "folder",
                    description: Text("This folder is empty")
                )
            } else {
                switch state.selectedViewMode {
                case .list:
                    FileListView(viewModel: viewModel)
                case .icon:
                    FileIconView(viewModel: viewModel)
                case .column:
                    FileColumnView(viewModel: viewModel)
                }
            }
        }
    }
}
