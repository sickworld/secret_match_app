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

    var icon: String {
        switch self {
        case .female: return "figure.dress.line.vertical.figure"
        case .male: return "figure.stand"
        case .skip: return "minus.circle"
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
