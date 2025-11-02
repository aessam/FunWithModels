import Foundation
import os.log

struct SearchResult: Codable, Identifiable {
    let id = UUID()
    let title: String
    let snippet: String
    let url: String

    enum CodingKeys: String, CodingKey {
        case title, snippet, url
    }
}

class SearchService {
    static let shared = SearchService()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "FunWithModels", category: "SearchService")

    private init() {}

    func search(query: String) async throws -> [SearchResult] {
        logger.info("🔍 SearchService.search() called with query: '\(query)'")

        // URL encode the query
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            logger.error("❌ Failed to URL encode query")
            throw SearchError.invalidQuery
        }

        // Use DuckDuckGo HTML version (simpler than Lite)
        let urlString = "https://html.duckduckgo.com/html/?q=\(encodedQuery)"
        logger.debug("🌐 Fetching URL: \(urlString)")

        guard let url = URL(string: urlString) else {
            logger.error("❌ Invalid URL constructed")
            throw SearchError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10.0

        logger.debug("📡 Making network request to DuckDuckGo...")
        let (data, response) = try await URLSession.shared.data(for: request)
        logger.info("✅ Network request completed, received \(data.count) bytes")

        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("❌ Response is not HTTPURLResponse")
            throw SearchError.networkError
        }

        logger.debug("📊 HTTP Status Code: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            logger.error("❌ HTTP error: status code \(httpResponse.statusCode)")
            throw SearchError.networkError
        }

        guard let html = String(data: data, encoding: .utf8) else {
            logger.error("❌ Failed to decode HTML as UTF-8")
            throw SearchError.decodingError
        }

        logger.debug("📄 HTML length: \(html.count) characters")
        let results = parseHTMLResults(from: html)
        logger.info("✅ Parsed \(results.count) search results")

        return results
    }

    private func parseHTMLResults(from html: String) -> [SearchResult] {
        logger.debug("🔬 Starting HTML parsing...")
        var results: [SearchResult] = []

        // DuckDuckGo HTML uses <a class="result__a"> for links
        // Split by result divs
        let resultDivs = html.components(separatedBy: "class=\"result ")

        logger.debug("  Found \(resultDivs.count) potential result divs")

        for (index, div) in resultDivs.enumerated() {
            if index == 0 { continue } // Skip header
            if results.count >= 10 { break }

            // Extract title - look for result__a link
            var title = ""
            if let titleStart = div.range(of: "class=\"result__a\""),
               let hrefStart = div.range(of: ">", range: titleStart.upperBound..<div.endIndex),
               let titleEnd = div.range(of: "</a>", range: hrefStart.upperBound..<div.endIndex) {
                title = String(div[hrefStart.upperBound..<titleEnd.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .stripHTMLTags()
                    .decodingHTMLEntities()
            }

            // Extract URL - look for uddg parameter (DuckDuckGo's redirect URL)
            var url = ""
            if let uddgStart = div.range(of: "//duckduckgo.com/l/?uddg="),
               let uddgEnd = div.range(of: "&", range: uddgStart.upperBound..<div.endIndex) {
                let encodedURL = String(div[uddgStart.upperBound..<uddgEnd.lowerBound])
                url = encodedURL.removingPercentEncoding ?? encodedURL
            } else if let hrefStart = div.range(of: "href=\""),
                      let hrefEnd = div.range(of: "\"", range: hrefStart.upperBound..<div.endIndex) {
                url = String(div[hrefStart.upperBound..<hrefEnd.lowerBound])
                if url.hasPrefix("//duckduckgo.com/l/?uddg=") {
                    url = url.components(separatedBy: "uddg=").last?.components(separatedBy: "&").first?.removingPercentEncoding ?? url
                }
            }

            // Extract snippet - look for result__snippet
            var snippet = ""
            if let snippetStart = div.range(of: "class=\"result__snippet\""),
               let contentStart = div.range(of: ">", range: snippetStart.upperBound..<div.endIndex),
               let contentEnd = div.range(of: "</a>", range: contentStart.upperBound..<div.endIndex) {
                snippet = String(div[contentStart.upperBound..<contentEnd.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .stripHTMLTags()
                    .decodingHTMLEntities()
            }

            // Clean up URL
            if url.hasPrefix("http") && !title.isEmpty {
                // Use title as snippet if snippet is empty
                if snippet.isEmpty {
                    snippet = "No description available"
                }

                results.append(SearchResult(
                    title: title,
                    snippet: snippet,
                    url: url
                ))
                logger.debug("  ✅ Result #\(results.count): \(title.prefix(50))...")
            }
        }

        logger.info("🔬 Parsing complete: found \(results.count) results")
        return results
    }
}

enum SearchError: LocalizedError {
    case invalidQuery
    case invalidURL
    case networkError
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidQuery:
            return "Invalid search query"
        case .invalidURL:
            return "Invalid URL"
        case .networkError:
            return "Network error occurred"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}

extension String {
    func decodingHTMLEntities() -> String {
        var result = self
        let entities: [String: String] = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&#39;": "'",
            "&apos;": "'",
            "&nbsp;": " ",
            "&#x27;": "'",
            "&rsquo;": "'",
            "&lsquo;": "'",
            "&rdquo;": "\"",
            "&ldquo;": "\""
        ]

        for (entity, character) in entities {
            result = result.replacingOccurrences(of: entity, with: character)
        }

        return result
    }

    func stripHTMLTags() -> String {
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
}
