import Foundation

struct Match: Identifiable, Codable {
    let id: String
    let other: String
    let type: String
    let message: String?
    let created_at: String
}
