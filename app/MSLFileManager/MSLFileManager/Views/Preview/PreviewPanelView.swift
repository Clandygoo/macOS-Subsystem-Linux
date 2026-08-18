import SwiftUI

struct PreviewPanelView: View {
    @EnvironmentObject private var state: AppState
    @ObservedObject var viewModel: BrowserViewModel

    var body: some View {
        VStack(spacing: 16) {
            if let itemId = state.selectedItems.first,
               let item = viewModel.items.first(where: { $0.id == itemId }) {
                Image(nsImage: item.icon)
                    .resizable()
                    .frame(width: 64, height: 64)

                Text(item.name)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                if item.isDirectory {
                    Text("Folder")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(item.displaySize)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(item.displayDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if item.isRemote {
                    HStack {
                        Image(systemName: "externaldrive")
                            .font(.caption)
                        Text("Linux VM")
                            .font(.caption)
                    }
                    .foregroundStyle(.green)
                }
            } else {
                ContentUnavailableView(
                    "No Selection",
                    systemImage: "hand.tap",
                    description: Text("Select a file to preview")
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
