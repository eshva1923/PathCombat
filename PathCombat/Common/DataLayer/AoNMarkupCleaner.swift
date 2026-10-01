import Foundation

enum AoNMarkupCleaner {
    static func stripLinks(_ text: String) -> String {
        var result = text
        result = result.replacingOccurrences(of: #"\{\{[^{}]*?"([^"]*)"[^{}]*?\}\}"#, with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\{\{[^{}]*?\}\}"#, with: "", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\[([^\]]*)\]\([^)]*\)"#, with: "$1", options: .regularExpression)
        return result
    }

    static let actionCostMap: [String: Int] = [
        "Reaction": -1,
        "Free Action": 0,
        "Single Action": 1,
        "Two Actions": 2,
        "Three Actions": 3
    ]
}
