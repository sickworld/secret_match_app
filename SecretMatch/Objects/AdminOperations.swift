import Foundation

struct AdminNumberOverview: Decodable {
    let number: String
    let allowed: Bool
    let active: Bool
    let lastActivity: Int
    let gender: String?
    let pinConfigured: Bool
    let counts: AdminNumberCounts
    let recentActivity: [AdminNumberActivity]
    let devices: [AdminDeviceStatus]
    let recentLogs: [AdminEventLogEntry]

    private enum CodingKeys: String, CodingKey {
        case number, allowed, active, gender, counts, devices
        case lastActivity = "last_activity"
        case pinConfigured = "pin_configured"
        case recentActivity = "recent_activity"
        case recentLogs = "recent_logs"
    }
}

struct AdminNumberCounts: Decodable {
    let sentRequests: Int
    let receivedRequests: Int
    let sentActions: Int
    let receivedActions: Int
    let matches: Int

    private enum CodingKeys: String, CodingKey {
        case sentRequests = "sent_requests"
        case receivedRequests = "received_requests"
        case sentActions = "sent_actions"
        case receivedActions = "received_actions"
        case matches
    }
}

struct AdminNumberActivity: Decodable, Identifiable {
    let id: String
    let kind: String
    let direction: String
    let counterpart: String
    let type: String
    let createdAt: String
    let hasMessage: Bool

    private enum CodingKeys: String, CodingKey {
        case id, kind, direction, counterpart, type
        case createdAt = "created_at"
        case hasMessage = "has_message"
    }
}

struct AdminDeliveryDiagnostic: Decodable, Identifiable {
    let id: String
    let sourceNumber: String
    let targetNumber: String
    let kind: String
    let interactionType: String
    let state: String
    let retryCount: Int
    let errorCode: String
    let createdAt: String
    let updatedAt: String
    let steps: [AdminEventLogEntry]

    private enum CodingKeys: String, CodingKey {
        case id, kind, state, steps
        case sourceNumber = "source_number"
        case targetNumber = "target_number"
        case interactionType = "interaction_type"
        case retryCount = "retry_count"
        case errorCode = "error_code"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum InteractionDeliveryStatus: Equatable {
    case delivered(count: Int)
    case queued(count: Int)
    case partiallyDelivered(delivered: Int, queued: Int)
    case failed
}
