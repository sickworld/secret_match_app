import Foundation

struct ActionDefinition: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var emoji: String
    var color: String
    var category: String
    var direction: String
    var targetGender: String
    var enabled: Bool
    var sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, name, emoji, color, category, direction, enabled
        case targetGender = "target_gender"
        case sortOrder = "sort_order"
    }

    var displayTitle: String {
        emoji.isEmpty ? name : "\(emoji) \(name)"
    }

    static let fallbacks = [
        ActionDefinition(id: "bjob", name: "Blow-Job", emoji: "👄", color: "#3E9ED6", category: "play", direction: "offer", targetGender: "male", enabled: true, sortOrder: 10),
        ActionDefinition(id: "hjob", name: "Hand-Job", emoji: "✋", color: "#E6923E", category: "play", direction: "offer", targetGender: "any", enabled: true, sortOrder: 20),
        ActionDefinition(id: "ljob", name: "Lick-Job", emoji: "👅", color: "#D65C8D", category: "play", direction: "offer", targetGender: "female", enabled: true, sortOrder: 30)
    ]

    static func fallback(for id: String) -> ActionDefinition {
        fallbacks.first { $0.id == id }
            ?? ActionDefinition(id: id, name: id.capitalized, emoji: "✨", color: "#E83E8C", category: "play", direction: "neutral", targetGender: "any", enabled: true, sortOrder: 999)
    }
}

struct ActionDefinitionsResponse: Decodable {
    let actions: [ActionDefinition]
}
