import Foundation

struct AdminFeedback: Identifiable, Decodable {
    let id: String
    let rating: Int?
    let functionalityRating: Int?
    let easeOfUseRating: Int?
    let designRating: Int?
    let createdAt: String

    private enum CodingKeys: String, CodingKey {
        case id
        case rating
        case functionalityRating = "functionality_rating"
        case easeOfUseRating = "ease_of_use_rating"
        case designRating = "design_rating"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = Self.decodeString(from: container, forKey: .id) ?? UUID().uuidString
        rating = Self.decodeInt(from: container, forKey: .rating)
        functionalityRating = Self.decodeInt(from: container, forKey: .functionalityRating)
        easeOfUseRating = Self.decodeInt(from: container, forKey: .easeOfUseRating)
        designRating = Self.decodeInt(from: container, forKey: .designRating)
        createdAt = Self.decodeString(from: container, forKey: .createdAt) ?? "Unbekannt"
    }

    private static func decodeInt(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> Int? {
        if let value = try? container.decode(Int.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(String.self, forKey: key) {
            return Int(value)
        }
        return nil
    }

    private static func decodeString(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> String? {
        if let value = try? container.decode(String.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Int.self, forKey: key) {
            return String(value)
        }
        return nil
    }
}
