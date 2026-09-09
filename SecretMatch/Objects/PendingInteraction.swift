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
    let actionRequestIDs: [UUID]

    var userMessage: String {
        guard queuedCount > 0 else {
            return messages.joined(separator: "\n")
        }

        let queuedMessage = InteractionQueueWording.waitingDescription(
            reportedShipmentCount: 1,
            actionCount: queuedCount
        ) + " sicher und geht automatisch raus, sobald die Verbindung wieder da ist."

        guard !messages.isEmpty else { return queuedMessage }
        return messages.joined(separator: "\n") + "\n" + queuedMessage
    }
}

struct ActionWithdrawalError: LocalizedError {
    let message: String

    var errorDescription: String? { message }
}

enum InteractionQueueWording {
    static func shipmentCount(reportedShipmentCount: Int?, actionCount: Int) -> Int {
        guard actionCount > 0 else { return 0 }
        guard let reportedShipmentCount, reportedShipmentCount > 0 else { return actionCount }
        return min(reportedShipmentCount, actionCount)
    }

    static func summary(reportedShipmentCount: Int?, actionCount: Int) -> String {
        let actions = max(0, actionCount)
        let shipments = shipmentCount(
            reportedShipmentCount: reportedShipmentCount,
            actionCount: actions
        )
        let shipmentText = shipments == 1 ? "1 Versand" : "\(shipments) Versandvorgänge"
        let actionText = actions == 1 ? "1 Aktion" : "\(actions) Aktionen"
        return "\(shipmentText) mit \(actionText)"
    }

    static func waitingDescription(reportedShipmentCount: Int?, actionCount: Int) -> String {
        let shipments = shipmentCount(
            reportedShipmentCount: reportedShipmentCount,
            actionCount: actionCount
        )
        let verb = shipments == 1 ? "wartet" : "warten"
        return "\(summary(reportedShipmentCount: shipments, actionCount: actionCount)) \(verb)"
    }
}
