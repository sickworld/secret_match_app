import Foundation

struct PendingTelemetryEvent: Codable, Identifiable {
    let id: UUID
    let occurredAt: String
    let severity: String
    let category: String
    let eventType: String
    let deviceID: String
    let targetNumber: String?
    let requestID: String?
    let status: String?
    let context: [String: String]

    private enum CodingKeys: String, CodingKey {
        case id, severity, category, status, context
        case occurredAt = "occurred_at"
        case eventType = "event_type"
        case deviceID = "device_id"
        case targetNumber = "target_number"
        case requestID = "request_id"
    }
}
