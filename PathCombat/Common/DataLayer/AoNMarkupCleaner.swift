import Foundation

/// Strips Archive of Nethys's link markup down to the visible text, shared by every AoN
/// importer (spells, conditions, ...).
enum AoNMarkupCleaner {
    /// `{{rules 2387 "emanation"}}` becomes `emanation`; Markdown-style `[text](url)` links
    /// become `text`.
    static func stripLinks(_ text: String) -> String {
        var result = text
        result = result.replacingOccurrences(of: #"\{\{[^{}]*?"([^"]*)"[^{}]*?\}\}"#, with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\{\{[^{}]*?\}\}"#, with: "", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\[([^\]]*)\]\([^)]*\)"#, with: "$1", options: .regularExpression)
        return result
    }

    /// Maps AoN's `actions` field (e.g. "Two Actions") onto the app's action-cost encoding
    /// (see `CombatAction.speedValues`). Costs outside this map are durations or ranges (e.g.
    /// "10 minutes", "Single Action to Three Actions") — callers should treat those as Special
    /// (4) and keep the raw text somewhere so it isn't lost.
    static let actionCostMap: [String: Int] = [
        "Reaction": -1,
        "Free Action": 0,
        "Single Action": 1,
        "Two Actions": 2,
        "Three Actions": 3
    ]
}
