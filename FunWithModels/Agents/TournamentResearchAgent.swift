import Foundation
import FoundationModels
import os.log

/// Tournament Research Agent - Actually executes the research tournament
final class TournamentResearchAgent: Tool {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "FunWithModels", category: "TournamentResearchAgent")

    let name = "research"
    let description = """
    Executes a tournament-style research workflow: searches, fetches pairs of sources,
    compares them, and returns only the best summary that answers the user's question.
    """

    @Generable
    struct Arguments {
        @Guide(description: "The user's question to research")
        let userQuestion: String
    }

    typealias Output = String

    nonisolated func call(arguments: Arguments) async throws -> String {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "FunWithModels", category: "TournamentResearchAgent")

        logger.info("🏆 TournamentResearchAgent starting tournament")
        logger.info("   Question: \(arguments.userQuestion)")

        // Step 1: Search
        logger.info("🔍 Searching...")
        let searchResults = try await SearchService.shared.search(query: arguments.userQuestion)

        guard !searchResults.isEmpty else {
            return "No search results found for the query."
        }

        logger.info("✅ Found \(searchResults.count) results")

        // Step 2: Tournament - Process pairs until we have a winner
        let candidates = Array(searchResults.prefix(8)) // Start with top 8 results
        let fetchAgent = WebFetchAgent()

        logger.info("🏆 Starting knockout tournament with \(candidates.count) sources")

        // Keep track of fetched summaries
        var summaries: [(url: String, title: String, summary: String)] = []

        // Round 1: Fetch pairs and compare
        for i in stride(from: 0, to: min(4, candidates.count), by: 2) {
            guard i + 1 < candidates.count else { break }

            let result1 = candidates[i]
            let result2 = candidates[i + 1]

            logger.info("⚔️ Fetching pair \(i/2 + 1): \(result1.title) vs \(result2.title)")

            // Fetch both in parallel
            async let summary1 = fetchAgent.fetchAndSummarize(url: result1.url, focus: arguments.userQuestion)
            async let summary2 = fetchAgent.fetchAndSummarize(url: result2.url, focus: arguments.userQuestion)

            let (s1, s2) = try await (summary1, summary2)

            // Simple scoring: longer summary + keyword match = better
            let keywords = arguments.userQuestion.lowercased().components(separatedBy: " ")
            var score1 = s1.count / 100 // Length score
            var score2 = s2.count / 100

            for keyword in keywords where keyword.count > 3 {
                if s1.lowercased().contains(keyword) { score1 += 10 }
                if s2.lowercased().contains(keyword) { score2 += 10 }
            }

            if score1 > score2 {
                summaries.append((url: result1.url, title: result1.title, summary: s1))
                logger.info("  ✅ Winner: \(result1.title) (score: \(score1) vs \(score2))")
            } else {
                summaries.append((url: result2.url, title: result2.title, summary: s2))
                logger.info("  ✅ Winner: \(result2.title) (score: \(score2) vs \(score1))")
            }
        }

        // Pick the best from winners
        guard let best = summaries.max(by: { $0.summary.count < $1.summary.count }) else {
            return "Failed to process search results."
        }

        logger.info("🏆 Tournament complete! Winner: \(best.title)")

        return """
        Based on multiple sources, here's what I found:

        \(best.summary)

        Source: \(best.title)
        URL: \(best.url)

        (This answer was selected from \(summaries.count) sources in a knockout comparison)
        """
    }
}
