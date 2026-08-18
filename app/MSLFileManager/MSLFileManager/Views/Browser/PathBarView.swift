import SwiftUI

struct PathBarView: View {
    let path: String
    @State private var isEditing = false
    @State private var editPath = ""

    var body: some View {
        HStack(spacing: 4) {
            if isEditing {
                TextField("Path", text: $editPath, onCommit: {
                    isEditing = false
                })
                .textFieldStyle(.roundedBorder)
                .font(.caption)
            } else {
                HStack(spacing: 4) {
                    ForEach(Array(pathComponents.enumerated()), id: \.offset) { index, component in
                        if index > 0 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                        }

                        Text(component)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                .onTapGesture {
                    isEditing = true
                    editPath = path
                }
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
