import Foundation

struct PendingInteraction: Codable, Identifiable {
    enum Kind: String, Codable {
        case match
        case action
    }

    let id: UUID
    let batchID: UUID
    let senderNumber: String
    let targetNumber: String
    let type: String
    let kind: Kind
    let message: String?
    let createdAt: Date
    var retryCount: Int
    var nextAttemptAt: Date
}

struct InteractionSubmissionResult {
    let messages: [String]
    let queuedCount: Int

    var userMessage: String {
        guard queuedCount > 0 else {
            return messages.joined(separator: "\n")
        }

        let queuedMessage = queuedCount == 1
            ? "1 Aktion ist in der Sende-Warteschlange und wird automatisch erneut versucht."
            : "\(queuedCount) Aktionen sind in der Sende-Warteschlange und werden automatisch erneut versucht."

        guard !messages.isEmpty else { return queuedMessage }
        return messages.joined(separator: "\n") + "\n" + queuedMessage
    }
}
