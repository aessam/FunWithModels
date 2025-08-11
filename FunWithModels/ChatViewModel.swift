import Foundation
import FoundationModels
import SwiftUI
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isGenerating = false
    @Published var showModelUnavailableAlert = false
    
    private var languageModel: SystemLanguageModel?
    private var session: LanguageModelSession?
    
    init() {
        setupWelcomeMessage()
    }
    
    private func setupWelcomeMessage() {
        messages.append(Message(
            content: "Hello! I'm an AI assistant powered by Apple's Foundation Models. Ask me anything!",
            isUser: false
        ))
    }
    
    func checkModelAvailability() {
        Task {
            do {
                let model = SystemLanguageModel.default
                if await model.isAvailable {
                    languageModel = model
                    session = LanguageModelSession(
                        model: model,
                        instructions: {
                            """
                            You are a helpful, friendly AI assistant. 
                            Provide clear, concise, and accurate responses.
                            Be conversational but professional.
                            If you're not sure about something, say so.
                            """
                        }
                    )
                } else {
                    showModelUnavailableAlert = true
                }
            } catch {
                print("Error initializing model: \(error)")
                showModelUnavailableAlert = true
            }
        }
    }
    
    func sendMessage(_ text: String) async {
        let userMessage = Message(content: text, isUser: true)
        messages.append(userMessage)
        
        guard let session = session else {
            messages.append(Message(
                content: "Sorry, the AI model is not available. Please check your device settings.",
                isUser: false
            ))
            return
        }
        
        isGenerating = true
        
        do {
            if #available(iOS 26.1, *) {
                var responseText = ""
                let stream = session.streamResponse(to: text)
                
                for try await chunk in stream {
                    responseText += chunk.content
                }
                
                if !responseText.isEmpty {
                    messages.append(Message(content: responseText, isUser: false))
                }
            } else {
                let response = try await session.respond(to: text)
                messages.append(Message(content: response.content, isUser: false))
            }
        } catch {
            messages.append(Message(
                content: "Sorry, I encountered an error: \(error.localizedDescription)",
                isUser: false
            ))
        }
        
        isGenerating = false
    }
    
    func clearChat() {
        messages.removeAll()
        setupWelcomeMessage()
    }
}
