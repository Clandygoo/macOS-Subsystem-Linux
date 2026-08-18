import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var state: AppState
    @State private var browserViewModel = BrowserViewModel()
    @State private var sidebarSelectedItem: SidebarItem?

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                SidebarView(browserViewModel: browserViewModel)
                    .environmentObject(state)
                SidebarFooterView()
                    .environmentObject(state)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 250)
        } detail: {
            VStack(spacing: 0) {
                TabBarView(browserViewModel: browserViewModel)
                    .environmentObject(state)

                HStack(spacing: 0) {
                    VStack(spacing: 0) {
                        PathBarView(path: browserViewModel.currentPath)

                        FileBrowserView(viewModel: browserViewModel)
                            .environmentObject(state)
                    }

                    if state.isPreviewVisible {
                        Divider()
                        PreviewPanelView(viewModel: browserViewModel)
                            .environmentObject(state)
                            .frame(width: 200)
                    }
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
        .onChange(of: state.activeTabID) { _, newTabID in
            guard let tab = state.tabs.first(where: { $0.id == newTabID }) else { return }
            browserViewModel.navigateTo(tab.path, isRemote: tab.isRemote)
        }
        .onChange(of: state.sidebarSelection) { _, newValue in
            guard let newValue else { return }
            if let url = newValue.localURL {
                browserViewModel.navigateTo(url.path, isRemote: false)
            } else if newValue.isRemote {
                let path: String
                switch newValue {
                case .vm: path = "/"
                case .vmDisk(let id): path = "/mnt/disks/\(id)"
                case .mount(let id): path = "/mnt/ntfs/\(id)"
                default: path = "/"
                }
                browserViewModel.navigateTo(path, isRemote: true)
            }
        }
        .task {
            await browserViewModel.loadContents(at: state.currentPath.path)
        }
    }
}

struct SidebarFooterView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        VStack(spacing: 4) {
            Divider()

            HStack {
                Image(systemName: state.vmStatus.isRunning ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(state.vmStatus.isRunning ? .green : .red)
                    .font(.caption)

                Text("VM: \(state.vmStatus.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }
}
