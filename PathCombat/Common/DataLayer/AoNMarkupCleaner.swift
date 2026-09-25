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
}
