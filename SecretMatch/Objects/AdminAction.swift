struct AdminAction: Identifiable, Decodable {
    let id: String
    let sender_number: String
    let receiver_number: String
    let action_type: String
    let created_at: String
}
