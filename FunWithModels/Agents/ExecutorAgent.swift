import Foundation
import FoundationModels
import os.log

/// Executor agent - executes plans using tools, compares results knockout-style
final class ExecutorAgent: Tool {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "FunWithModels", category: "ExecutorAgent")

    let name = "executor"
    let description = """
    Executes research plans by using webSearch and webFetch tools strategically.
    Can fetch multiple sources and compare them to find the best information.
    Returns the most relevant, concise answer to the user's question.
    """

    @Generable
    struct Arguments {
        @Guide(description: "The execution plan (e.g., 'search for X, fetch top 2 results, compare and summarize')")
        let plan: String

        @Guide(description: "The user's original question to answer")
        let userQuestion: String
    }

    typealias Output = String

    nonisolated func call(arguments: Arguments) async throws -> String {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "FunWithModels", category: "ExecutorAgent")

        logger.info("⚙️ ExecutorAgent executing plan")
        logger.info("   Plan: \(arguments.plan)")
        logger.info("   Question: \(arguments.userQuestion)")

        return """
        Executor Agent - Execution Guide:

        Plan: \(arguments.plan)
        User Question: \(arguments.userQuestion)

        ⚠️ CRITICAL: You MUST execute steps in order. Do NOT skip ahead.

        STEP 1: SEARCH FIRST (MANDATORY)
        → Call webSearch tool NOW with an appropriate query
        → Wait for search results before doing ANYTHING else
        → DO NOT call webFetch until you have real URLs from search results

        STEP 2: ANALYZE RESULTS
        → Look at the search results you just received
        → Identify the 2-3 most promising URLs based on:
          * Relevance to user question
          * Source credibility
          * Recency of information

        STEP 3: FETCH FROM REAL URLS
        → Call webFetch on each selected URL (max 2-3)
        → Use specific focus that matches the user's question
        → Example: webFetch(url: "actual_url_from_search", focus: "specific topic")

        STEP 4: COMPARE SUMMARIES
        → Compare the fetched summaries knockout-style:
          * Which best answers the user's question?
          * Which has most relevant/recent information?
          * Eliminate weaker sources

        STEP 5: SYNTHESIZE ANSWER
        → Create concise answer from the BEST source
        → Cite the source clearly
        → Be specific and actionable

        🚨 START NOW: Call webSearch tool with query related to: \(arguments.userQuestion)
        """
    }
}
