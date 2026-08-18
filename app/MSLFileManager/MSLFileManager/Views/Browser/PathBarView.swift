import SwiftUI

struct PathBarView: View {
    let path: String

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(pathComponents.enumerated()), id: \.offset) { index, component in
                if index > 0 {
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(component)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var pathComponents: [String] {
        path.components(separatedBy: "/").filter { !$0.isEmpty }
    }
}
