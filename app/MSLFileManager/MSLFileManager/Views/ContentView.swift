import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var state: AppState
    @State private var browserViewModel = BrowserViewModel()
    @State private var showArchivePreview = false
    @State private var archivePath: String?

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
                ChromeTabBar(browserViewModel: browserViewModel)
                    .environmentObject(state)

                HStack(spacing: 0) {
                    VStack(spacing: 0) {
                        PathBarView(path: browserViewModel.currentPath)
                            .environmentObject(state)

                        FileBrowserView(viewModel: browserViewModel)
                            .environmentObject(state)
                            .onDrop(of: [.fileURL], delegate: FileDropDelegate(viewModel: browserViewModel))
                    }

                    if state.isPreviewVisible {
                        Divider()
                        Group {
                            if showArchivePreview, let archivePath {
                                ArchivePreviewView(archivePath: archivePath)
                            } else {
                                PreviewPanelView(viewModel: browserViewModel)
                                    .environmentObject(state)
                            }
                        }
                        .frame(width: 250)
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

struct FileDropDelegate: DropDelegate {
    let viewModel: BrowserViewModel

    func performDrop(info: DropInfo) -> Bool {
        guard let items = info.itemProviders(for: [.fileURL]).first else { return false }
        items.loadObject(ofClass: NSURL.self) { url, _ in
            if let url = url as? URL {
                let dest = (viewModel.currentPath as NSString).appendingPathComponent(url.lastPathComponent)
                try? FileManager.default.copyItem(at: url, to: URL(fileURLWithPath: dest))
                DispatchQueue.main.async {
                    viewModel.refresh()
                }
            }
        }
        return true
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

                Text("\(L10n.t("sidebar.vm_status")): \(state.vmStatus.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }
}
