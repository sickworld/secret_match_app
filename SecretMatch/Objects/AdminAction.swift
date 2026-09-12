struct AdminAction: Identifiable, Decodable {
    let id: String
    let sender_number: String
    let receiver_number: String
    let action_type: String
    let created_at: String
    let action_name: String?
    let action_emoji: String?
    let action_color: String?
    let action_category: String?
    let action_direction: String?
}
