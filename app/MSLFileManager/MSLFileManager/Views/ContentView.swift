import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var state: AppState
    @State private var browserViewModel = BrowserViewModel()
    @State private var showArchivePreview = false
    @State private var archivePath: String?
    @FocusState private var isFileListFocused: Bool

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
                            .focused($isFileListFocused)
                            .onDrop(of: [.fileURL], delegate: FileDropDelegate(viewModel: browserViewModel))
                    }

                    if state.isPreviewVisible && state.selectedViewMode != .gallery {
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
            .toolbar(.hidden, for: .automatic)
            .toolbar {
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
        .onAppear {
            browserViewModel.appState = state
            isFileListFocused = true
        }
        .onKeyPress(.space) {
            quickLookSelected()
            return .handled
        }

        if state.isVMStarting {
            VMStartupOverlay()
                .environmentObject(state)
        }
    }

    private func quickLookSelected() {
        guard let itemId = state.selectedItems.first,
              let item = browserViewModel.items.first(where: { $0.id == itemId }),
              let url = item.url else { return }
        NSWorkspace.shared.open(url)
    }
}

struct FileDropDelegate: DropDelegate {
    let viewModel: BrowserViewModel

    func performDrop(info: DropInfo) -> Bool {
        guard let providers = info.itemProviders(for: [.fileURL]).first else { return false }
        providers.loadObject(ofClass: NSURL.self) { url, _ in
            if let url = url as? URL {
                let dest = (viewModel.currentPath as NSString).appendingPathComponent(url.lastPathComponent)
                if !FileManager.default.fileExists(atPath: dest) {
                    try? FileManager.default.copyItem(at: url, to: URL(fileURLWithPath: dest))
                }
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

struct VMStartupOverlay: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "terminal.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)

                Text("MSL")
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)

                Text("Linux Subsystem")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.7))

                VStack(spacing: 12) {
                    ProgressView(value: state.vmLifecycle.startupProgress)
                        .progressViewStyle(.linear)
                        .frame(width: 300)
                        .tint(.green)

                    Text(state.vmLifecycle.startupMessage)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(40)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
    }
}
