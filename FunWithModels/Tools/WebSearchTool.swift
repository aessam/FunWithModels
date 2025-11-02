import Foundation
import FoundationModels
import os.log

/// Raw web search tool - just returns search results
final class WebSearchTool: Tool {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "FunWithModels", category: "WebSearchTool")

    let name = "webSearch"
    let description = "Searches the web and returns a list of relevant URLs with titles and snippets."

    @Generable
    struct Arguments {
        @Guide(description: "The search query")
        let query: String
    }

    typealias Output = String

    nonisolated func call(arguments: Arguments) async throws -> String {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "FunWithModels", category: "WebSearchTool")

        logger.info("🔍 WebSearchTool: '\(arguments.query)'")

        let results = try await SearchService.shared.search(query: arguments.query)
        let top5 = Array(results.prefix(5))

        var output = "Search results for '\(arguments.query)':\n\n"
        for (i, result) in top5.enumerated() {
            output += "[\(i+1)] \(result.title)\n    URL: \(result.url)\n    \(result.snippet)\n\n"
        }

        logger.info("✅ Returned \(top5.count) results")
        return output
    }
}
