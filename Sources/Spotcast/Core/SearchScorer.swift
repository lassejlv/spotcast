import Foundation

enum SearchScorer {
    static func score(action: LauncherAction, query: String) -> Double {
        let normalizedQuery = normalize(query)
        if normalizedQuery.isEmpty {
            return 1
        }

        let titleScore = scoreText(normalize(action.title), query: normalizedQuery) * 1.35
        let subtitleScore = scoreText(normalize(action.subtitle), query: normalizedQuery) * 0.85
        let keywordScore = action.keywords
            .map { scoreText(normalize($0), query: normalizedQuery) }
            .max() ?? 0

        return max(titleScore, subtitleScore, keywordScore)
    }

    private static func scoreText(_ text: String, query: String) -> Double {
        guard !text.isEmpty else {
            return 0
        }

        if text == query {
            return 320
        }

        if text.hasPrefix(query) {
            return 250 - Double(max(0, text.count - query.count)) * 0.2
        }

        if let range = text.range(of: query) {
            let distance = text.distance(from: text.startIndex, to: range.lowerBound)
            return 205 - Double(distance) * 0.75
        }

        guard let fuzzy = subsequenceScore(text: text, query: query) else {
            return 0
        }

        return fuzzy
    }

    private static func subsequenceScore(text: String, query: String) -> Double? {
        let textChars = Array(text)
        let queryChars = Array(query)

        var queryIndex = 0
        var firstMatch = -1
        var lastMatch = -1
        var gaps = 0
        var streak = 0
        var adjacency = 0

        for index in textChars.indices {
            if queryIndex >= queryChars.count {
                break
            }

            if textChars[index] == queryChars[queryIndex] {
                if firstMatch == -1 {
                    firstMatch = index
                }

                if lastMatch >= 0 {
                    let gap = index - lastMatch - 1
                    gaps += max(0, gap)
                    if gap == 0 {
                        streak += 1
                        adjacency += streak
                    } else {
                        streak = 0
                    }
                }

                lastMatch = index
                queryIndex += 1
            }
        }

        guard queryIndex == queryChars.count, firstMatch >= 0, lastMatch >= 0 else {
            return nil
        }

        let span = lastMatch - firstMatch + 1
        return 130
            - Double(gaps) * 1.4
            - Double(max(0, span - queryChars.count)) * 0.35
            + Double(adjacency) * 2.5
    }

    private static func normalize(_ value: String) -> String {
        value.folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
