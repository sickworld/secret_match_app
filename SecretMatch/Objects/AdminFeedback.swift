import Foundation

struct AdminFeedback: Identifiable, Decodable {
    let id: String
    let rating: Int
    let functionalityRating: Int
    let createdAt: String

    private enum CodingKeys: String, CodingKey {
        case id
        case rating
        case functionalityRating = "functionality_rating"
        case createdAt = "created_at"
    }
}
