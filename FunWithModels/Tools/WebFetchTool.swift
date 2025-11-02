import Foundation
import FoundationModels
import os.log

/// Raw web fetch tool - delegates to WebFetchAgent for smart summarization
final class WebFetchTool: Tool {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "FunWithModels", category: "WebFetchTool")

    let name = "webFetch"
    let description = "Fetches a webpage and returns a concise summary. Handles context limits intelligently."

    @Generable
    struct Arguments {
        @Guide(description: "The URL to fetch")
        let url: String

        @Guide(description: "What to focus on when summarizing (e.g., 'product features', 'recipe details', 'news summary')")
        let focus: String
    }

    typealias Output = String

    nonisolated func call(arguments: Arguments) async throws -> String {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "FunWithModels", category: "WebFetchTool")

        logger.info("🌐 WebFetchTool: \(arguments.url)")
        logger.info("   Focus: \(arguments.focus)")

        // Delegate to WebFetchAgent for smart fetch + summarization
        let agent = WebFetchAgent()
        let summary = try await agent.fetchAndSummarize(url: arguments.url, focus: arguments.focus)

        logger.info("✅ Returned summary (\(summary.count) chars)")
        return summary
    }
}
