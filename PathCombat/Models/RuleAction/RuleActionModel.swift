import Foundation
import SwiftData

enum RuleActionKind: String, Codable, CaseIterable, Identifiable {
    case action
    case activity

    var id: Self { self }

    var displayName: String {
        switch self {
        case .action: return "Action"
        case .activity: return "Activity"
        }
    }
}

@Model
final class RuleAction {
    @Attribute(.unique) var id: UUID
    var name: String
    var kind: RuleActionKind
    var speed: Int?
    var details: String
    var tags: [String]
    var aonID: Int?

    init(name: String?, id: UUID?, kind: RuleActionKind?, speed: Int? = nil, details: String?,
         tags: [String]? = nil, aonID: Int? = nil) {
        self.id = id ?? UUID()
        self.name = name ?? "Unnamed action"
        self.kind = kind ?? .action
        self.speed = speed
        self.details = details ?? ""
        self.tags = tags ?? []
        self.aonID = aonID
    }

    static func new(kind: RuleActionKind) -> RuleAction {
        RuleAction(name: nil, id: nil, kind: kind, details: nil)
    }

    var aonURL: URL? {
        guard let aonID else { return nil }
        return URL(string: "https://2e.aonprd.com/Actions.aspx?ID=\(aonID)")
    }

    func matchesSearch(_ query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let lowered = query.lowercased()
        if name.lowercased().contains(lowered) { return true }
        if tags.contains(where: { $0.lowercased().contains(lowered) }) { return true }
        return false
    }
}
