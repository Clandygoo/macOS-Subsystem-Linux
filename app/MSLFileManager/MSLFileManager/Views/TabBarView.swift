import SwiftUI

struct ChromeTabBar: View {
    @EnvironmentObject private var state: AppState
    @ObservedObject var browserViewModel: BrowserViewModel

    var body: some View {
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
                    .font(.system(size: 11, weight: .medium))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .padding(.leading, 2)
            .padding(.trailing, 8)

            Spacer()
        }
        .frame(height: 36)
        .background(Color(nsColor: .controlBackgroundColor))
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
                .font(.system(size: 9))
                .foregroundStyle(isActive ? .white : .secondary)
                .padding(.leading, 10)

            Text(tab.title)
                .font(.system(size: 11))
                .lineLimit(1)
                .foregroundStyle(isActive ? .white : .primary)
                .padding(.horizontal, 6)

            if isHovering || isActive {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(isActive ? .white.opacity(0.7) : .secondary)
                        .frame(width: 14, height: 14)
                        .background(Circle().fill(isActive ? Color.white.opacity(0.2) : Color.secondary.opacity(0.15)))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 6)
            }
        }
        .frame(height: 28)
        .background(
            isActive
                ? AnyShapeStyle(Color.accentColor)
                : AnyShapeStyle(isHovering ? Color.secondary.opacity(0.15) : Color.clear)
        )
        .clipShape(TabShape())
        .padding(.top, 4)
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
