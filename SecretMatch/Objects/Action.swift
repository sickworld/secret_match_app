struct Action: Identifiable, Codable {
    let id: Int
    let sender_number: String
    let receiver_number: String
    let action_type: String
    let created_at: String
}
