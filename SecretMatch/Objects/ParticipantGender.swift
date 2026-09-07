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
