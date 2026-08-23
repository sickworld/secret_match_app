import Foundation

struct AdminFeedback: Identifiable, Decodable {
    let id: String
    let rating: Int
    let functionalityRating: Int
    let easeOfUseRating: Int?
    let designRating: Int?
    let reuseRating: Int?
    let createdAt: String

    private enum CodingKeys: String, CodingKey {
        case id
        case rating
        case functionalityRating = "functionality_rating"
        case easeOfUseRating = "ease_of_use_rating"
        case designRating = "design_rating"
        case reuseRating = "reuse_rating"
        case createdAt = "created_at"
    }
}
