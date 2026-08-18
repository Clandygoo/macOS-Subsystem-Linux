import SwiftUI

struct AIAssistantPanel: View {
    @EnvironmentObject private var state: AppState
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("AI Assistant")
                    .font(.headline)
                Spacer()
                Button {
                    NSApplication.shared.keyWindow?.close()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()

            Divider()

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        ChatBubbleView(message: message)
                    }
                }
                .padding()
            }

            Divider()

            HStack {
                TextField("Ask AI...", text: $messageText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        sendMessage()
                    }

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .disabled(messageText.isEmpty)
            }
            .padding()
        }
    }

    private func sendMessage() {
        guard !messageText.isEmpty else { return }

        let userMessage = ChatMessage(role: .user, content: messageText)
        messages.append(userMessage)
        messageText = ""

        Task {
            let aiResponse = ChatMessage(role: .assistant, content: "AI response placeholder")
            messages.append(aiResponse)
        }
    }
}

enum ChatRole: Sendable {
    case user
    case assistant
    case system
}

struct ChatMessage: Identifiable, Sendable {
    let id = UUID()
    let role: ChatRole
    let content: String
}

struct ChatBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(10)
                    .background(message.role == .user ? Color.accentColor : Color.secondary.opacity(0.1))
                    .foregroundStyle(message.role == .user ? .white : .primary)
                    .cornerRadius(12)
            }

            if message.role == .assistant {
                Spacer()
            }
        }
    }
}
