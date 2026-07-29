import Foundation

struct AdminDashboard: Decodable {
    let activeParticipants: Int
    let allowedParticipants: Int
    let matches: Int
    let actions: Int
    let latestActivity: String
    let topTestActive: Bool
    let dummyDataActive: Bool
    let billboardSessions: Int
    let billboardRotationSeconds: Int
    let telegramConfigured: Bool
    let pluginVersion: String
    let wordpressTime: String
    let apiOK: Bool

    private enum CodingKeys: String, CodingKey {
        case activeParticipants = "active_participants"
        case allowedParticipants = "allowed_participants"
        case matches
        case actions
        case latestActivity = "latest_activity"
        case topTestActive = "top_test_active"
        case dummyDataActive = "dummy_data_active"
        case billboardSessions = "billboard_sessions"
        case billboardRotationSeconds = "billboard_rotation_seconds"
        case telegramConfigured = "telegram_configured"
        case pluginVersion = "plugin_version"
        case wordpressTime = "wordpress_time"
        case apiOK = "api_ok"
    }
}

struct AdminParticipants: Decodable {
    let allowed: [String]
    let active: [AdminActiveParticipant]
}

struct AdminActiveParticipant: Identifiable, Decodable {
    let number: String
    let lastActivity: Int

    var id: String { "\(number)-\(lastActivity)" }

    private enum CodingKeys: String, CodingKey {
        case number
        case lastActivity = "last_activity"
    }
}
