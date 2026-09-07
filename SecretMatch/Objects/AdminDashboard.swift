import Foundation

struct AdminDashboard: Decodable {
    let activeParticipants: Int
    let allowedParticipants: Int
    let matches: Int
    let requests: Int?
    let actions: Int
    let latestActivity: String
    let topTestActive: Bool
    let dummyDataActive: Bool
    let billboardSessions: Int
    let billboardRotationSeconds: Int
    let telegramConfigured: Bool
    let apnsConfigured: Bool?
    let adminPushDevices: Int?
    let pluginVersion: String
    let wordpressTime: String
    let apiOK: Bool
    let billboardOnline: Bool?
    let billboardLastSeen: Int?
    let billboardWidth: Int?
    let billboardHeight: Int?
    let billboardMode: String?
    let billboards: [AdminBillboardStatus]?
    let topPeople: [TopPerson]?
    let matchMessageOptions: [String]?
    let devices: [AdminDeviceStatus]?

    private enum CodingKeys: String, CodingKey {
        case activeParticipants = "active_participants"
        case allowedParticipants = "allowed_participants"
        case matches
        case requests
        case actions
        case latestActivity = "latest_activity"
        case topTestActive = "top_test_active"
        case dummyDataActive = "dummy_data_active"
        case billboardSessions = "billboard_sessions"
        case billboardRotationSeconds = "billboard_rotation_seconds"
        case telegramConfigured = "telegram_configured"
        case apnsConfigured = "apns_configured"
        case adminPushDevices = "admin_push_devices"
        case pluginVersion = "plugin_version"
        case wordpressTime = "wordpress_time"
        case apiOK = "api_ok"
        case billboardOnline = "billboard_online"
        case billboardLastSeen = "billboard_last_seen"
        case billboardWidth = "billboard_width"
        case billboardHeight = "billboard_height"
        case billboardMode = "billboard_mode"
        case billboards
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
    let deviceID: String?
    let name: String?
    let number: String
    let batteryLevel: Int
    let batteryState: String
    let appVersion: String
    let lastSeen: Int
    let online: Bool?

    var id: String { deviceID ?? "\(number)-\(appVersion)" }

    var isOnline: Bool {
        online ?? (lastSeen >= Int(Date().timeIntervalSince1970) - 180)
    }

    var lastSeenDescription: String {
        let seconds = max(0, Int(Date().timeIntervalSince1970) - lastSeen)
        if seconds < 60 { return "gerade eben" }
        if seconds < 3600 { return "vor \(seconds / 60) Min." }
        return "vor \(seconds / 3600) Std."
    }

    private enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case name
        case number
        case batteryLevel = "battery_level"
        case batteryState = "battery_state"
        case appVersion = "app_version"
        case lastSeen = "last_seen"
        case online
    }
}

struct AdminBillboardStatus: Decodable, Identifiable {
    let billboardID: String
    let name: String
    let lastSeen: Int
    let online: Bool
    let width: Int
    let height: Int
    let mode: String

    var id: String { billboardID }

    var lastSeenDescription: String {
        guard lastSeen > 0 else { return "noch kein Signal" }
        let seconds = max(0, Int(Date().timeIntervalSince1970) - lastSeen)
        if seconds < 60 { return "gerade eben" }
        if seconds < 3600 { return "vor \(seconds / 60) Min." }
        return "vor \(seconds / 3600) Std."
    }

    var resolution: String {
        width > 0 && height > 0 ? "\(width) × \(height)" : "Auflösung unbekannt"
    }

    var modeLabel: String {
        mode == "top" ? "Top 16" : (mode == "normal" ? "Normalbetrieb" : "Modus unbekannt")
    }

    private enum CodingKeys: String, CodingKey {
        case billboardID = "billboard_id"
        case name
        case lastSeen = "last_seen"
        case online
        case width
        case height
        case mode
    }
}

struct ParticipantRangeResponse: Decodable {
    let targetMax: Int
    let allowedCount: Int
    let addedCount: Int
    let removedCount: Int

    private enum CodingKeys: String, CodingKey {
        case targetMax = "target_max"
        case allowedCount = "allowed_count"
        case addedCount = "added_count"
        case removedCount = "removed_count"
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
        pins = (try? container.decode([String: String].self, forKey: .pins)) ?? [:]
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
