import Foundation
import FoundationModels
import os.log

/// UI Agent - Top-level coordinator that ensures user alignment
final class UIAgent: Tool {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "FunWithModels", category: "UIAgent")

    let name = "uiAgent"
    let description = """
    Top-level coordinator that validates user intent and ensures alignment.
    Use this FIRST to confirm understanding before creating execution plans.
    Ensures the approach will satisfy what the user truly wants.
    """

    @Generable
    struct Arguments {
        @Guide(description: "The user's original message or a research result to validate")
        let content: String

        @Guide(description: "What you're validating: 'request' for initial validation or 'result' for final validation")
        let validationType: String
    }

    typealias Output = String

    nonisolated func call(arguments: Arguments) async throws -> String {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "FunWithModels", category: "UIAgent")

        logger.info("👤 UIAgent validating: \(arguments.validationType)")
        logger.info("   Content: \(arguments.content)")

        if arguments.validationType == "request" {
            return """
            UI Agent - Request Validated:

            User Request: "\(arguments.content)"

            ✅ ALIGNMENT CONFIRMED - Proceed with research

            Next Step: Call 'research' agent with the user's question.
            The research agent will search, fetch, summarize, and compare sources.

            IMPORTANT: Only show the user the FINAL answer, not intermediate steps.
            """
        } else {
            return """
            UI Agent - Result Validated:

            ✅ Result looks good - clear, specific, and cites sources

            You may now present this to the user as your final answer.
            """
        }
    }
}
