import Foundation

struct EventAnnouncement: Codable, Identifiable, Equatable {
    let id: String
    let message: String
    let tone: String
    let enabled: Bool
    let startsAt: Int?
    let endsAt: Int?
    let createdAt: Int
    let updatedAt: Int
    let live: Bool

    private enum CodingKeys: String, CodingKey {
        case id, message, tone, enabled, live
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum EventAnnouncementTone: String, CaseIterable, Identifiable {
    case info
    case highlight
    case urgent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .info: return "Info"
        case .highlight: return "Highlight"
        case .urgent: return "Dringend"
        }
    }

    var systemImage: String {
        switch self {
        case .info: return "info.circle.fill"
        case .highlight: return "sparkles"
        case .urgent: return "exclamationmark.triangle.fill"
        }
    }
}
