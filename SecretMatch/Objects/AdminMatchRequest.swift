struct AdminMatchRequest: Identifiable, Decodable {
    let id: String
    let participantA: String
    let participantB: String
    let type: String
    let message: String
    let createdAt: String
    let isMatched: Bool

    private enum CodingKeys: String, CodingKey {
        case id, type, message
        case participantA = "participant_a"
        case participantB = "participant_b"
        case createdAt = "created_at"
        case isMatched = "is_matched"
    }
}
