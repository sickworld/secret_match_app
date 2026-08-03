import Foundation

enum ParticipantGender: String, CaseIterable, Identifiable {
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
    let needsGender: Bool

    private enum CodingKeys: String, CodingKey {
        case number
        case needsGender = "needs_gender"
    }
}
