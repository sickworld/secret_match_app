import Foundation

enum ParticipantGender: String, CaseIterable, Identifiable, Codable {
    case female
    case male
    case skip

    var id: String { rawValue }

    var title: String {
        switch self {
        case .female: return "Frau"
        case .male: return "Mann"
        case .skip: return "Lieber nicht"
        }
    }

    var symbol: String {
        switch self {
        case .female: return "♀"
        case .male: return "♂"
        case .skip: return "–"
        }
    }
}

struct ParticipantLoginResponse: Decodable {
    let number: String?
    let needsPin: Bool
    let needsGender: Bool

    private enum CodingKeys: String, CodingKey {
        case number
        case needsPin = "needs_pin"
        case needsGender = "needs_gender"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        number = try container.decodeIfPresent(String.self, forKey: .number)
        needsPin = try container.decodeIfPresent(Bool.self, forKey: .needsPin) ?? false
        needsGender = try container.decode(Bool.self, forKey: .needsGender)
    }
}

struct ParticipantLoginRequirements {
    let needsPin: Bool
    let needsGender: Bool
}

struct ParticipantLoginErrorResponse: Decodable {
    let code: String
}

enum ParticipantLoginError: LocalizedError {
    case pinRequired
    case invalidCredentials
    case tooManyAttempts
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .pinRequired: return "Bitte persönliche PIN eingeben."
        case .invalidCredentials: return "Nummer oder PIN ist nicht gültig."
        case .tooManyAttempts: return "Zu viele Login-Versuche. Bitte kurz warten."
        case .invalidResponse: return "Der Login-Server antwortet nicht korrekt."
        }
    }
}
