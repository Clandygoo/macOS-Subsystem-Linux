import SwiftUI

struct FileBrowserView: View {
    @EnvironmentObject private var state: AppState
    @ObservedObject var viewModel: BrowserViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.items.isEmpty {
                ContentUnavailableView(
                    L10n.t("browser.no_items"),
                    systemImage: "folder",
                    description: Text(L10n.t("browser.empty_folder"))
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
