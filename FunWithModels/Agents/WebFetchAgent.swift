import Foundation
import os.log

/// Agent that fetches web pages and creates context-aware summaries
class WebFetchAgent {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "FunWithModels", category: "WebFetchAgent")

    func fetchAndSummarize(url: String, focus: String) async throws -> String {
        logger.info("📄 WebFetchAgent fetching: \(url)")

        guard let urlObj = URL(string: url),
              url.hasPrefix("http") else {
            throw FetchError.invalidURL
        }

        var request = URLRequest(url: urlObj)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15.0

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw FetchError.networkError
        }

        guard let html = String(data: data, encoding: .utf8) else {
            throw FetchError.decodingError
        }

        logger.info("✅ Fetched \(html.count) chars, extracting text...")

        // Extract readable text
        let text = extractText(from: html)

        // Smart chunking to fit context (keep it under 2000 chars for safety)
        let summary = createFocusedSummary(text: text, focus: focus, maxLength: 2000)

        logger.info("✅ Created summary: \(summary.count) chars")

        return """
        Summary of \(url)
        Focus: \(focus)

        \(summary)
        """
    }

    private func extractText(from html: String) -> String {
        var text = html

        // Remove scripts, styles
        text = text.replacingOccurrences(of: "<script[^>]*>[\\s\\S]*?</script>", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "<style[^>]*>[\\s\\S]*?</style>", with: "", options: .regularExpression)

        // Remove HTML tags
        text = text.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)

        // Decode entities & clean whitespace
        text = text.decodingHTMLEntities()
        text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func createFocusedSummary(text: String, focus: String, maxLength: Int) -> String {
        // Simple heuristic: find paragraphs containing focus keywords
        let focusTerms = focus.lowercased().components(separatedBy: " ")
        let paragraphs = text.components(separatedBy: "\n").filter { !$0.isEmpty }

        var relevant: [String] = []
        var totalLength = 0

        for para in paragraphs {
            let lower = para.lowercased()
            let isRelevant = focusTerms.contains { lower.contains($0) }

            if isRelevant || relevant.isEmpty {
                relevant.append(para)
                totalLength += para.count

                if totalLength > maxLength {
                    break
                }
            }
        }

        let combined = relevant.joined(separator: "\n\n")
        return String(combined.prefix(maxLength))
    }
}

enum FetchError: LocalizedError {
    case invalidURL
    case networkError
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .networkError: return "Network error"
        case .decodingError: return "Decoding error"
        }
    }
}
