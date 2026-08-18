import SwiftUI

struct TabBarView: View {
    @EnvironmentObject private var state: AppState
    @ObservedObject var browserViewModel: BrowserViewModel

    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(state.tabs) { tab in
                        TabItemView(
                            tab: tab,
                            isActive: tab.id == state.activeTabID,
                            onClose: {
                                state.closeTab(id: tab.id)
                            }
                        )
                        .onTapGesture {
                            state.switchTab(to: tab.id)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }

            Button {
                state.addTab()
            } label: {
                Image(systemName: "plus")
                    .font(.caption)
                    .padding(6)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 8)
        }
        .frame(height: 32)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }
}

struct TabItemView: View {
    let tab: FileTab
    let isActive: Bool
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: tab.isRemote ? "externaldrive" : "folder")
                .font(.caption2)
                .foregroundStyle(isActive ? .white : .secondary)

            Text(tab.title)
                .font(.caption)
                .lineLimit(1)
                .foregroundStyle(isActive ? .white : .primary)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(isActive ? .white.opacity(0.7) : .secondary)
            }
            .buttonStyle(.plain)
            .opacity(isActive ? 1 : 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(isActive ? Color.accentColor : Color.clear)
        .cornerRadius(6)
        .onHover { hovering in
            // could add hover effect
        }
    }
}
