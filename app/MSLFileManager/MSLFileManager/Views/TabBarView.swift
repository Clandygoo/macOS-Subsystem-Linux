import SwiftUI

struct ChromeTabBar: View {
    @EnvironmentObject private var state: AppState
    @ObservedObject var browserViewModel: BrowserViewModel

    var body: some View {
        HStack(spacing: 0) {
            // Navigation buttons (left side of tabs)
            HStack(spacing: 2) {
                Button {
                    browserViewModel.goBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .medium))
                        .frame(width: 28, height: 28)
                }
                .disabled(!browserViewModel.canGoBack)
                .buttonStyle(.plain)

                Button {
                    browserViewModel.goForward()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .frame(width: 28, height: 28)
                }
                .disabled(!browserViewModel.canGoForward)
                .buttonStyle(.plain)
            }
            .padding(.leading, 8)
            .padding(.trailing, 4)

            // Tabs
            HStack(spacing: 0) {
                ForEach(Array(state.tabs.enumerated()), id: \.element.id) { index, tab in
                    ChromeTabItem(
                        tab: tab,
                        isActive: tab.id == state.activeTabID,
                        isLast: index == state.tabs.count - 1,
                        onSelect: { state.switchTab(to: tab.id) },
                        onClose: { state.closeTab(id: tab.id) }
                    )
                }

                Button {
                    state.addTab()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .medium))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .padding(.leading, 2)
                .padding(.trailing, 8)
            }

            Spacer()

            // View mode buttons (right side)
            HStack(spacing: 4) {
                ViewModePicker()

                SortMenu(viewModel: browserViewModel)

                Button {
                    withAnimation {
                        state.isPreviewVisible.toggle()
                    }
                } label: {
                    Image(systemName: "sidebar.right")
                        .font(.system(size: 13))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }
            .padding(.trailing, 8)
        }
        .frame(height: 42)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}

struct ChromeTabItem: View {
    let tab: FileTab
    let isActive: Bool
    let isLast: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: tab.isRemote ? "externaldrive" : "folder.fill")
                .font(.system(size: 11))
                .foregroundStyle(isActive ? .white : .secondary)
                .padding(.leading, 12)

            Text(tab.title)
                .font(.system(size: 12))
                .lineLimit(1)
                .foregroundStyle(isActive ? .white : .primary)
                .padding(.horizontal, 8)

            if isHovering || isActive {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(isActive ? .white.opacity(0.7) : .secondary)
                        .frame(width: 16, height: 16)
                        .background(Circle().fill(isActive ? Color.white.opacity(0.2) : Color.secondary.opacity(0.15)))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
            }
        }
        .frame(height: 32)
        .background(
            isActive
                ? AnyShapeStyle(Color.accentColor)
                : AnyShapeStyle(isHovering ? Color.secondary.opacity(0.15) : Color.clear)
        )
        .clipShape(TabShape())
        .padding(.top, 5)
        .padding(.leading, isLast ? 0 : -2)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .onTapGesture { onSelect() }
    }
}

struct TabShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let r: CGFloat = 6

        path.move(to: CGPoint(x: r, y: 0))
        path.addLine(to: CGPoint(x: w - r, y: 0))
        path.addQuadCurve(to: CGPoint(x: w, y: r), control: CGPoint(x: w, y: 0))
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: 0, y: r))
        path.addQuadCurve(to: CGPoint(x: r, y: 0), control: CGPoint(x: 0, y: 0))

        return path
    }
}
