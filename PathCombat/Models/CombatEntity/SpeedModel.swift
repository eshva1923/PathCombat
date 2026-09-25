import Foundation

struct Speed: Codable, Hashable {
    var value: Int
    /// Empty string means land speed; otherwise the movement type, e.g. "swimming", "flying", "burrow".
    var type: String

    init(value: Int, type: String = "") {
        self.value = value
        self.type = type
    }

    var displayText: String {
        type.isEmpty ? "\(value)" : "\(value) \(type)"
    }

    static func parse(_ text: String) -> Speed? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        let parts = trimmed.split(separator: " ", maxSplits: 1)
        guard let value = Int(parts[0]) else { return nil }
        let type = parts.count > 1 ? String(parts[1]) : ""
        return Speed(value: value, type: type)
    }

    static func parseList(_ text: String) -> [Speed] {
        text.split(separator: ",").compactMap { Speed.parse(String($0)) }
    }

    static let defaultLandSpeed = [Speed(value: 30)]
}
