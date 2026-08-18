import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var state: AppState
    @State private var browserViewModel = BrowserViewModel()

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 250)
        } detail: {
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    PathBarView(path: browserViewModel.currentPath)

                    FileBrowserView(viewModel: browserViewModel)
                }

                if state.isPreviewVisible {
                    Divider()
                    PreviewPanelView()
                        .frame(width: 200)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    ViewModePicker()

                    SortMenu(viewModel: browserViewModel)

                    Button {
                        withAnimation {
                            state.isPreviewVisible.toggle()
                        }
                    } label: {
                        Image(systemName: "sidebar.right")
                    }
                }

                ToolbarItemGroup(placement: .navigation) {
                    Button {
                        browserViewModel.goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(!browserViewModel.canGoBack)

                    Button {
                        browserViewModel.goForward()
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(!browserViewModel.canGoForward)

                    Button {
                        browserViewModel.goToParent()
                    } label: {
                        Image(systemName: "chevron.up")
                    }
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .task {
            await browserViewModel.loadContents(at: state.currentPath.path)
        }
    }
}
