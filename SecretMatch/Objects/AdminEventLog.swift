import Foundation

struct AdminEventLogEntry: Identifiable, Decodable {
    let id: String
    let occurredAt: String
    let receivedAt: String
    let severity: String
    let category: String
    let eventType: String
    let actorType: String
    let actorRef: String
    let subjectRef: String
    let deviceID: String
    let requestID: String
    let status: String
    let context: [String: LogContextValue]

    var title: String {
        let titles = [
            "interaction_queued": "Sendung eingereiht",
            "interaction_send_started": "Sendeversuch gestartet",
            "interaction_retry_scheduled": "Erneuter Versuch geplant",
            "interaction_delivered": "Sendung zugestellt",
            "interaction_rejected": "Sendung abgelehnt",
            "queue_backlog_detected": "Warteschlange erkannt",
            "queue_stalled": "Warteschlange hängt",
            "queue_cleared": "Warteschlange abgearbeitet",
            "device_first_seen": "iPad erstmals verbunden",
            "device_app_version_changed": "App-Version geändert",
            "device_offline": "iPad offline",
            "device_recovered": "iPad wieder online",
            "billboard_offline": "Billboard offline",
            "billboard_recovered": "Billboard wieder online",
            "battery_warning": "Akkustand niedrig",
            "battery_critical": "Akkustand kritisch",
            "battery_recovered": "Akkustand erholt",
            "connection_lost": "Verbindung verloren",
            "connection_recovered": "Verbindung wiederhergestellt",
            "notification_delivery_failed": "Benachrichtigung fehlgeschlagen",
            "participant_login_success": "Teilnehmer angemeldet",
            "participant_login_failed": "Teilnehmer-Login fehlgeschlagen",
            "participant_pin_set_success": "PIN angelegt",
            "participant_pin_set_failed": "PIN-Anlage fehlgeschlagen",
            "participant_profile_updated_success": "Teilnehmerprofil aktualisiert",
            "participant_profile_updated_failed": "Profiländerung fehlgeschlagen",
            "participant_logout_success": "Teilnehmer abgemeldet",
            "participant_logout_failed": "Abmeldung fehlgeschlagen",
            "match_request_submitted_success": "Match-Wunsch angenommen",
            "match_request_submitted_failed": "Match-Wunsch abgelehnt",
            "action_submitted_success": "Aktion angenommen",
            "action_submitted_failed": "Aktion abgelehnt",
            "feedback_submitted_success": "Feedback eingegangen",
            "feedback_submitted_failed": "Feedback fehlgeschlagen",
            "admin_login_success": "Admin angemeldet",
            "admin_login_failed": "Admin-Login fehlgeschlagen",
            "admin_logout_success": "Admin abgemeldet",
            "admin_logout_failed": "Admin-Abmeldung fehlgeschlagen",
        ]
        if let title = titles[eventType] {
            return title
        }
        if eventType.hasPrefix("admin_") {
            return eventType.hasSuffix("_failed") ? "Admin-Aktion fehlgeschlagen" : "Admin-Änderung gespeichert"
        }
        return eventType.replacingOccurrences(of: "_", with: " ").capitalized
    }

    var references: String {
        var parts: [String] = []
        if !actorRef.isEmpty { parts.append(actorRef.displayEventReference) }
        if !subjectRef.isEmpty { parts.append("→ \(subjectRef.displayEventReference)") }
        if !requestID.isEmpty { parts.append("ID \(requestID.prefix(8))") }
        return parts.joined(separator: " ")
    }

    var csvRow: [String] {
        [
            id, occurredAt, severity, category, eventType, status,
            actorType, actorRef, subjectRef, requestID,
            context.keys.sorted().map { "\($0)=\(context[$0]?.displayValue ?? "")" }.joined(separator: "; ")
        ]
    }

    private enum CodingKeys: String, CodingKey {
        case id, severity, category, status, context
        case occurredAt = "occurred_at"
        case receivedAt = "received_at"
        case eventType = "event_type"
        case actorType = "actor_type"
        case actorRef = "actor_ref"
        case subjectRef = "subject_ref"
        case deviceID = "device_id"
        case requestID = "request_id"
    }
}

struct AdminEventLogExamplesResponse: Decodable {
    let created: Int
    let available: Int
}

enum LogContextValue: Decodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case strings([String])
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String].self) {
            self = .strings(value)
        } else {
            self = .unknown
        }
    }

    var displayValue: String {
        switch self {
        case .string(let value): return value
        case .number(let value):
            return value.rounded() == value ? String(Int(value)) : String(value)
        case .bool(let value): return value ? "ja" : "nein"
        case .strings(let values): return values.joined(separator: ", ")
        case .unknown: return "–"
        }
    }
}

struct AdminStatisticsResponse: Decodable {
    let current: AdminEventStatistics
    let lastEvent: AdminEventStatistics?

    private enum CodingKeys: String, CodingKey {
        case current
        case lastEvent = "last_event"
    }
}

struct AdminEventStatistics: Decodable {
    let generatedAt: String
    let completedAt: String?
    let startedAt: String
    let endedAt: String
    let allowedParticipants: Int
    let engagedParticipants: Int
    let requests: Int
    let matches: Int
    let actions: Int
    let requestsWithMessage: Int
    let matchRatePercent: Double
    let retryCount: Int
    let deliveryCount: Int
    let errorCount: Int
    let requestTypes: [AdminStatisticCount]
    let actionTypes: [AdminStatisticCount]
    let topParticipants: [AdminParticipantStatistic]?
    let timeline: [AdminStatisticTimelinePoint]

    private enum CodingKeys: String, CodingKey {
        case generatedAt = "generated_at"
        case completedAt = "completed_at"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case allowedParticipants = "allowed_participants"
        case engagedParticipants = "engaged_participants"
        case requests, matches, actions
        case requestsWithMessage = "requests_with_message"
        case matchRatePercent = "match_rate_percent"
        case retryCount = "retry_count"
        case deliveryCount = "delivery_count"
        case errorCount = "error_count"
        case requestTypes = "request_types"
        case actionTypes = "action_types"
        case topParticipants = "top_participants"
        case timeline
    }
}

struct AdminParticipantStatistic: Decodable, Identifiable {
    let number: String
    let sent: Int
    let received: Int
    let matches: Int

    var id: String { number }
    var activityTotal: Int { sent + received + matches * 2 }
}

struct AdminStatisticCount: Decodable, Identifiable {
    let name: String
    let count: Int
    var id: String { name }
}

struct AdminStatisticTimelinePoint: Decodable, Identifiable {
    let hour: String
    let requests: Int
    let matches: Int
    let actions: Int
    var id: String { hour }
    var total: Int { requests + matches + actions }
}

private extension String {
    var displayEventReference: String {
        allSatisfy(\.isNumber) ? displayEventNumber : self
    }
}
