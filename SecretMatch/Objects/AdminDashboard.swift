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
    let billboardOnline: Bool?
    let billboardLastSeen: Int?
    let billboardWidth: Int?
    let billboardHeight: Int?
    let billboardMode: String?
    let topPeople: [TopPerson]?
    let matchMessageOptions: [String]?
    let devices: [AdminDeviceStatus]?

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
        case billboardOnline = "billboard_online"
        case billboardLastSeen = "billboard_last_seen"
        case billboardWidth = "billboard_width"
        case billboardHeight = "billboard_height"
        case billboardMode = "billboard_mode"
        case topPeople = "top_people"
        case matchMessageOptions = "match_message_options"
        case devices
    }
}

struct TopPerson: Decodable, Identifiable {
    let number: String
    let gender: String?

    var id: String { number }

    var genderSymbol: String {
        switch gender {
        case "female": return "♀"
        case "male": return "♂"
        default: return "–"
        }
    }
}

struct AdminDeviceStatus: Decodable, Identifiable {
    let number: String
    let batteryLevel: Int
    let batteryState: String
    let appVersion: String
    let lastSeen: Int

    var id: String { "\(number)-\(lastSeen)" }

    private enum CodingKeys: String, CodingKey {
        case number
        case batteryLevel = "battery_level"
        case batteryState = "battery_state"
        case appVersion = "app_version"
        case lastSeen = "last_seen"
    }
}

struct EventResetResponse: Decodable {
    let backupCreatedAt: String
    let deleted: DeletedCounts

    struct DeletedCounts: Decodable {
        let matches: Int
        let requests: Int
        let actions: Int
        let feedback: Int?
    }

    private enum CodingKeys: String, CodingKey {
        case backupCreatedAt = "backup_created_at"
        case deleted
    }
}

struct AdminParticipants: Decodable {
    let allowed: [String]
    let active: [AdminActiveParticipant]
    let profiles: [AdminParticipantProfile]
    let pins: [String: String]

    init(allowed: [String], active: [AdminActiveParticipant], profiles: [AdminParticipantProfile] = [], pins: [String: String] = [:]) {
        self.allowed = allowed
        self.active = active
        self.profiles = profiles
        self.pins = pins
    }

    private enum CodingKeys: String, CodingKey {
        case allowed, active, profiles, pins
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        allowed = try container.decode([String].self, forKey: .allowed)
        active = try container.decode([AdminActiveParticipant].self, forKey: .active)
        profiles = try container.decodeIfPresent([AdminParticipantProfile].self, forKey: .profiles) ?? []
        pins = try container.decodeIfPresent([String: String].self, forKey: .pins) ?? [:]
    }
}

struct AdminParticipantProfile: Identifiable, Decodable {
    let number: String
    let gender: ParticipantGender

    var id: String { number }
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
