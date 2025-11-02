import SwiftUI
import FoundationModels

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var showModelSelection = true

    var body: some View {
        if showModelSelection {
            ModelSelectionView { model in
                viewModel.setupModel(model)
                showModelSelection = false
            }
        } else {
            chatView
        }
    }

    private var chatView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Foundation Models Chat")
                    .font(.largeTitle)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: {
                    showModelSelection = true
                    viewModel.clearChat()
                }) {
                    Text("Change Model")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
            }
            .padding()

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }

                        if viewModel.isGenerating {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Thinking...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: viewModel.messages.count) { _ in
                    withAnimation {
                        proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                    }
                }
            }

            Divider()

            HStack(spacing: 12) {
                TextField("Type a message...", text: $messageText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        sendMessage()
                    }

                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isGenerating)
            }
            .padding()
        }
    }
    
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        Task {
            await viewModel.sendMessage(trimmedMessage)
        }
        messageText = ""
    }
}

struct MessageBubble: View {
    let message: Message

    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.isUser ? "You" : "AI")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(message.content)
                    .padding(12)
                    .background(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(16)
            }

            if !message.isUser {
                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
}