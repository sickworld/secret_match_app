import SwiftUI

struct SentAction: Identifiable {
    let id = UUID()
    let toNumber: String
    let type: String
    let timestamp: Date
}
