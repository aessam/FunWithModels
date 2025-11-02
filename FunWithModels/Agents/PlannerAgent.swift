import Foundation
import FoundationModels
import os.log

/// Planner agent - creates executable plans given available tools
final class PlannerAgent: Tool {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "FunWithModels", category: "PlannerAgent")

    let name = "planner"
    let description = """
    Creates strategic execution plans for fulfilling user requests.
    Given the user's intent and available tools (webSearch, webFetch), creates
    a step-by-step plan that the executor can follow.
    """

    @Generable
    struct Arguments {
        @Guide(description: "The user's validated intent")
        let userIntent: String

        @Guide(description: "Available tools: webSearch, webFetch")
        let availableTools: String
    }

    typealias Output = String

    nonisolated func call(arguments: Arguments) async throws -> String {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "FunWithModels", category: "PlannerAgent")

        logger.info("🧠 PlannerAgent creating plan")
        logger.info("   Intent: \(arguments.userIntent)")

        return """
        Planner Agent - Strategic Plan:

        User Intent: \(arguments.userIntent)
        Available Tools: \(arguments.availableTools)

        RECOMMENDED PLAN:
        1. Search Phase: Use webSearch to find 3-5 relevant sources
        2. Selection Phase: Analyze results, identify top 2-3 most promising URLs
        3. Fetch Phase: Use webFetch on each selected URL with specific focus
        4. Comparison Phase: Compare fetched content, eliminate weaker sources
        5. Synthesis Phase: Create concise answer from best source(s)

        CONSTRAINTS:
        - Max 2-3 fetches to respect context limits
        - Each fetch must have clear focus aligned with user intent
        - Final answer must be concise and actionable

        Now hand this plan to the executor agent to execute.
        """
    }
}
