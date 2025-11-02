import Foundation
import FoundationModels
import SwiftUI
import Combine
import os.log

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isGenerating = false
    @Published var showModelUnavailableAlert = false

    private var languageModel: SystemLanguageModel?
    private var session: LanguageModelSession?
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "FunWithModels", category: "ChatViewModel")

    init() {
        setupWelcomeMessage()
        logger.info("🎬 ChatViewModel initialized")
    }
    
    private func setupWelcomeMessage() {
        messages.append(Message(
            content: "Hello! I'm an AI assistant powered by Apple's Foundation Models with autonomous web search. I can search the web when needed to provide current information. Ask me anything!",
            isUser: false
        ))
    }
    
    func checkModelAvailability() {
        Task {
            logger.info("🔍 Checking model availability...")
            let model = SystemLanguageModel.default

            switch model.availability {
            case .available:
                logger.info("✅ Model is available")
                languageModel = model

                // Initialize agent system with tournament research
                let uiAgent = UIAgent()
                let researchAgent = TournamentResearchAgent()

                logger.info("🔧 Initializing agent system: UI → Tournament Research")

                session = LanguageModelSession(
                    model: model,
                    tools: [uiAgent, researchAgent],
                    instructions: {
                        """
                        You are an AI assistant with autonomous web research capabilities.

                        ## YOUR TOOLS

                        1. uiAgent - Validates user requests (optional, use for complex queries)
                        2. research - Tournament-style research agent that:
                           - Searches the web
                           - Fetches multiple sources
                           - Compares them in knockout rounds
                           - Returns ONLY the best summary

                        ## SIMPLE WORKFLOW

                        For questions needing current information:

                        STEP 1: Call research agent
                        → research(userQuestion: "user's exact question")
                        → The agent does EVERYTHING internally:
                          * Searches
                          * Fetches 4-8 sources in pairs
                          * Compares them knockout-style
                          * Returns the WINNER summary

                        STEP 2: Present to user
                        → The research agent returns a complete summary
                        → You just present it to the user naturally
                        → DO NOT add "the research agent said..." - just present the answer

                        ## EXAMPLE

                        User: "Latest Apple rumors for November 2025"

                        You do:
                        1. Call research(userQuestion: "Latest Apple rumors for November 2025")
                        2. Get back a complete summary with source
                        3. Present it naturally to user

                        ❌ BAD response:
                        "The research agent found: Based on multiple sources..."

                        ✅ GOOD response:
                        "Based on recent reports from 9to5Mac, Apple is expected to announce several products in November 2025, including updated MacBook Pros with M4 chips and new iPad Air models. These announcements are rumored for early November.

                        Source: 9to5Mac"

                        ## KEY PRINCIPLES
                        - For simple questions → Answer directly
                        - For current/recent info → Use research agent
                        - Present results NATURALLY, not as "the agent said"
                        - The research agent handles ALL the complexity internally

                        Knowledge cutoff: October 2023. Use research for anything more recent.
                        """
                    }
                )
                logger.info("✅ Session initialized with tools")

            case .unavailable(let reason):
                logger.error("❌ Model unavailable: \(String(describing: reason))")
                showModelUnavailableAlert = true
            }
        }
    }

    func setupModel(_ model: SystemLanguageModel) {
        logger.info("⚙️ setupModel() called")
        languageModel = model

        // Initialize agent system with tournament research
        let uiAgent = UIAgent()
        let researchAgent = TournamentResearchAgent()

        logger.info("🔧 Creating agent system: UI → Tournament Research")

        session = LanguageModelSession(
            model: model,
            tools: [uiAgent, researchAgent],
            instructions: {
                """
                You are an AI assistant with autonomous web research capabilities.

                ## YOUR TOOLS

                1. uiAgent - Validates user requests (optional, use for complex queries)
                2. research - Tournament-style research agent that:
                   - Searches the web
                   - Fetches multiple sources
                   - Compares them in knockout rounds
                   - Returns ONLY the best summary

                ## SIMPLE WORKFLOW

                For questions needing current information:

                STEP 1: Call research agent
                → research(userQuestion: "user's exact question")
                → The agent does EVERYTHING internally:
                  * Searches
                  * Fetches 4-8 sources in pairs
                  * Compares them knockout-style
                  * Returns the WINNER summary

                STEP 2: Present to user
                → The research agent returns a complete summary
                → You just present it to the user naturally
                → DO NOT add "the research agent said..." - just present the answer

                ## EXAMPLE

                User: "Latest Apple rumors for November 2025"

                You do:
                1. Call research(userQuestion: "Latest Apple rumors for November 2025")
                2. Get back a complete summary with source
                3. Present it naturally to user

                ❌ BAD response:
                "The research agent found: Based on multiple sources..."

                ✅ GOOD response:
                "Based on recent reports from 9to5Mac, Apple is expected to announce several products in November 2025, including updated MacBook Pros with M4 chips and new iPad Air models. These announcements are rumored for early November.

                Source: 9to5Mac"

                ## KEY PRINCIPLES
                - For simple questions → Answer directly
                - For current/recent info → Use research agent
                - Present results NATURALLY, not as "the agent said"
                - The research agent handles ALL the complexity internally

                Knowledge cutoff: October 2023. Use research for anything more recent.
                """
            }
        )
        logger.info("✅ Session created successfully")
    }
    
    func sendMessage(_ text: String) async {
        logger.info("💬 sendMessage() called with: '\(text)'")

        let userMessage = Message(content: text, isUser: true)
        messages.append(userMessage)

        guard let session = session else {
            logger.error("❌ No session available")
            messages.append(Message(
                content: "Sorry, the AI model is not available. Please check your device settings.",
                isUser: false
            ))
            return
        }

        isGenerating = true
        logger.debug("⏳ isGenerating = true")

        do {
            // Simply send the user's message to the model
            // The model will autonomously decide if it needs to search
            // The Tool framework handles tool execution and feedback automatically

            logger.info("🤖 Sending message to Foundation Model...")

            if #available(iOS 26.1, *) {
                logger.debug("📡 Using streaming API")
                var responseText = ""
                let stream = session.streamResponse(to: text)

                for try await chunk in stream {
                    responseText = chunk.content
                    logger.debug("📦 Received chunk, total length: \(responseText.count)")
                }

                logger.info("✅ Streaming complete, response length: \(responseText.count)")

                if !responseText.isEmpty {
                    messages.append(Message(content: responseText, isUser: false))
                    logger.info("💬 Response added to messages")
                } else {
                    logger.warning("⚠️ Empty response received")
                }
            } else {
                logger.debug("📡 Using non-streaming API")
                let response = try await session.respond(to: text)
                logger.info("✅ Response received, length: \(response.content.count)")
                messages.append(Message(content: response.content, isUser: false))
            }

            // Log session transcript to see tool calls
            logger.info("📜 Session transcript entries: \(session.transcript.count)")

        } catch {
            logger.error("❌ Error during message generation: \(error.localizedDescription)")
            messages.append(Message(
                content: "Sorry, I encountered an error: \(error.localizedDescription)",
                isUser: false
            ))
        }

        isGenerating = false
        logger.debug("✅ isGenerating = false")
    }
    
    func clearChat() {
        messages.removeAll()
        setupWelcomeMessage()
    }
}
