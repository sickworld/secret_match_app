import Foundation

struct MatchDefinition: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var emoji: String
    var color: String
    var enabled: Bool
    var sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, name, emoji, color, enabled
        case sortOrder = "sort_order"
    }

    var displayTitle: String { emoji.isEmpty ? name : "\(emoji) \(name)" }

    static let fallbacks = [
        MatchDefinition(id: "normal", name: "Hot-Match", emoji: "❤️", color: "#E83E8C", enabled: true, sortOrder: 10),
        MatchDefinition(id: "hot", name: "Fuck-Match", emoji: "🍆", color: "#8E63D2", enabled: true, sortOrder: 20)
    ]

    nonisolated static func normalizedID(_ id: String) -> String {
        id.caseInsensitiveCompare("F-") == .orderedSame ? "hot" : id
    }

    static func fallback(for id: String) -> MatchDefinition {
        let normalized = normalizedID(id)
        return fallbacks.first { $0.id == normalized }
            ?? MatchDefinition(id: normalized, name: normalized.capitalized, emoji: "✨", color: "#E83E8C", enabled: true, sortOrder: 999)
    }
}

struct MatchDefinitionsResponse: Decodable {
    let matches: [MatchDefinition]
}
