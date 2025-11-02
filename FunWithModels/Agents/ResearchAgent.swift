import Foundation
import FoundationModels
import os.log

/// Research Agent - Plans AND executes research using tools
final class ResearchAgent: Tool {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "FunWithModels", category: "ResearchAgent")

    let name = "research"
    let description = """
    Research agent that searches, fetches, summarizes, and compares sources.
    Returns a synthesized answer from the best sources.
    """

    @Generable
    struct Arguments {
        @Guide(description: "The user's validated question/request")
        let userQuestion: String
    }

    typealias Output = String

    nonisolated func call(arguments: Arguments) async throws -> String {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "FunWithModels", category: "ResearchAgent")

        logger.info("🔬 ResearchAgent starting research")
        logger.info("   Question: \(arguments.userQuestion)")

        return """
        Research Agent - EXECUTE NOW:

        Question: \(arguments.userQuestion)

        🚨 CONTEXT MANAGEMENT - CRITICAL:

        The model has a 4096 token context limit. Each webFetch returns ~500 tokens.
        You can do AT MOST 2 fetches before running out of context.

        SIMPLIFIED WORKFLOW:

        STEP 1: SEARCH
        → Call webSearch with query
        → Analyze the titles and snippets in the results
        → Pick the SINGLE BEST URL based on title + snippet relevance

        STEP 2: FETCH WINNER
        → Call webFetch ONCE on the best URL
        → You'll get a focused summary

        STEP 3: ANSWER USER
        → Use the summary to answer the user's question
        → Cite the source
        → Be specific and concise

        ⚠️ DO NOT FETCH MULTIPLE SOURCES - Context limit will fail!
        ⚠️ Pick the best URL from search results based on title/snippet analysis
        ⚠️ Then fetch ONLY that one URL

        Execute silently and return ONLY your final answer to the user.
        """
    }
}
