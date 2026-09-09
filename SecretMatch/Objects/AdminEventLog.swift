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
            "interaction_queued": "Aktion eingereiht",
            "interaction_send_started": "Aktion wird gesendet",
            "interaction_retry_scheduled": "Erneuter Versuch geplant",
            "interaction_delivered": "Aktion zugestellt",
            "interaction_rejected": "Aktion abgelehnt",
            "action_withdrawn_locally": "Aktion aus Warteschlange entfernt",
            "action_withdrawn_success": "Aktion zurückgezogen",
            "action_withdrawn_failed": "Rückzug fehlgeschlagen",
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
        let resultSuffix = eventType.hasSuffix("_failed") ? "_failed" : "_success"
        let baseType = eventType.hasSuffix(resultSuffix)
            ? String(eventType.dropLast(resultSuffix.count))
            : eventType
        let adminTitles = [
            "admin_action_created": "Admin: Aktion angelegt",
            "admin_action_updated": "Admin: Aktion bearbeitet",
            "admin_action_deleted": "Admin: Aktion gelöscht",
            "admin_match_created": "Admin: Match angelegt",
            "admin_match_updated": "Admin: Match bearbeitet",
            "admin_match_deleted": "Admin: Match gelöscht",
            "admin_match_request_updated": "Admin: Match-Request bearbeitet",
            "admin_match_request_deleted": "Admin: Match-Request gelöscht",
            "admin_feedback_deleted": "Admin: Feedback gelöscht",
            "admin_credential_created": "Admin: Zugang angelegt",
            "admin_credential_deleted": "Admin: Zugang widerrufen",
            "admin_billboard_created": "Admin: Billboard angelegt",
            "admin_billboard_renamed": "Admin: Billboard umbenannt",
            "admin_billboard_deleted": "Admin: Billboard gelöscht",
            "admin_device_renamed": "Admin: iPad umbenannt",
            "admin_device_deleted": "Admin: iPad entfernt",
            "admin_participant_created": "Admin: Nummer freigegeben",
            "admin_participant_range_updated": "Admin: Nummernbereich geändert",
            "admin_participant_logged_out": "Admin: Teilnehmer abgemeldet",
            "admin_participant_deleted": "Admin: Teilnehmer gesperrt",
            "admin_participant_pin_reset": "Admin: PIN zurückgesetzt",
            "admin_participant_pin_updated": "Admin: PIN geändert",
            "admin_participant_gender_reset": "Admin: Gender zurückgesetzt",
            "admin_participant_gender_updated": "Admin: Gender geändert",
            "admin_participant_updated": "Admin: Teilnehmer geändert",
            "admin_quick_messages_updated": "Admin: Schnelltexte gespeichert",
            "admin_screensaver_item_created": "Admin: Medienbild angelegt",
            "admin_screensaver_item_updated": "Admin: Medienbild bearbeitet",
            "admin_screensaver_item_deleted": "Admin: Medienbild entfernt",
            "admin_screensaver_settings_updated": "Admin: Bildschirmschoner-Startzeit geändert",
            "admin_push_device_registered": "Admin-Gerät für Push registriert",
            "admin_push_device_unregistered": "Admin-Gerät von Push abgemeldet",
            "admin_event_log_examples_created": "Admin: Testprotokolle angelegt",
            "admin_event_reset": "Admin: Event-Reset",
            "admin_dummy_data_created": "Admin: Testdaten angelegt",
            "admin_dummy_data_deleted": "Admin: Testdaten gelöscht",
            "admin_billboard_top_test_started": "Admin: Billboard-Test gestartet",
            "admin_billboard_normal_mode_started": "Admin: Normalbetrieb gestartet",
            "admin_billboard_interval_updated": "Admin: Match-Einblendung geändert",
            "admin_billboard_access_revoked": "Admin: Billboard-Zugänge widerrufen",
            "admin_billboard_control_updated": "Admin: Billboard-Steuerung geändert",
            "wp_admin_numbers_generated": "WordPress: Nummern erzeugt",
            "wp_admin_numbers_deleted": "WordPress: Nummern gelöscht",
            "wp_admin_dummy_data_created": "WordPress: Testdaten angelegt",
            "wp_admin_dummy_data_deleted": "WordPress: Testdaten gelöscht",
            "wp_admin_callmebot_updated": "WordPress: CallMeBot geändert",
            "wp_admin_telegram_fuck_test_sent": "WordPress: Fuck-Match-Test gesendet",
            "wp_admin_telegram_hot_test_sent": "WordPress: Hot-Match-Test gesendet",
            "wp_admin_apns_test_sent": "WordPress: Push-Test gesendet",
            "wp_admin_telegram_settings_updated": "WordPress: Telegram geändert",
            "wp_admin_telegram_settings_deleted": "WordPress: Telegram gelöscht",
            "wp_admin_password_updated": "WordPress: Admin-Passwort geändert",
            "wp_admin_credential_created": "WordPress: Admin-Zugang angelegt",
            "wp_admin_credential_deleted": "WordPress: Admin-Zugang widerrufen",
            "wp_admin_session_settings_updated": "WordPress: Laufzeiten geändert",
            "wp_admin_quick_messages_updated": "WordPress: Schnelltexte gespeichert",
            "wp_admin_screensaver_item_created": "WordPress: Medienbild angelegt",
            "wp_admin_screensaver_item_updated": "WordPress: Medienbild bearbeitet",
            "wp_admin_screensaver_item_deleted": "WordPress: Medienbild entfernt",
            "wp_admin_screensaver_settings_updated": "WordPress: Bildschirmschoner-Startzeit geändert",
            "wp_admin_billboard_access_revoked": "WordPress: Billboard-Zugänge widerrufen",
            "wp_admin_billboard_top_test_started": "WordPress: Billboard-Test gestartet",
            "wp_admin_billboard_top_test_stopped": "WordPress: Billboard-Test beendet",
            "wp_admin_billboard_settings_updated": "WordPress: Billboard-Einstellungen geändert",
            "wp_admin_match_created": "WordPress: Match angelegt",
            "wp_admin_match_deleted": "WordPress: Match gelöscht",
            "wp_admin_all_matches_deleted": "WordPress: Alle Matches gelöscht",
            "wp_admin_all_match_requests_deleted": "WordPress: Alle Match-Requests gelöscht",
            "wp_admin_action_created": "WordPress: Aktion angelegt",
            "wp_admin_action_deleted": "WordPress: Aktion gelöscht",
            "wp_admin_all_actions_deleted": "WordPress: Alle Aktionen gelöscht",
            "wp_admin_feedback_deleted": "WordPress: Feedback gelöscht",
            "wp_admin_all_feedback_deleted": "WordPress: Alle Feedbacks gelöscht",
            "wp_admin_event_reset": "WordPress: Event-Reset",
        ]
        if let title = adminTitles[baseType] {
            return eventType.hasSuffix("_failed") ? "\(title) – fehlgeschlagen" : title
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
    let adminActionCount: Int?
    let adminFailureCount: Int?
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
        case adminActionCount = "admin_action_count"
        case adminFailureCount = "admin_failure_count"
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
