import Foundation
@testable import SecretMatch

func makeAdminStatisticsFixture() -> AdminEventStatistics {
    AdminEventStatistics(
        generatedAt: "2026-09-13T20:00:00Z",
        completedAt: "2026-09-13T22:00:00Z",
        startedAt: "2026-09-13T18:00:00Z",
        endedAt: "2026-09-13T22:00:00Z",
        allowedParticipants: 120,
        engagedParticipants: 84,
        requests: 64,
        matches: 22,
        actions: 91,
        requestsWithMessage: 18,
        matchRatePercent: 34.4,
        retryCount: 3,
        deliveryCount: 152,
        errorCount: 2,
        adminActionCount: 8,
        adminFailureCount: 1,
        participationRatePercent: 70,
        requestsPerParticipant: 0.76,
        actionsPerParticipant: 1.08,
        openRequests: 20,
        requestsWithMessagePercent: 28.1,
        withdrawnActions: 4,
        withdrawalRatePercent: 4.4,
        averageMatchMinutes: 17.5,
        medianMatchMinutes: 12,
        matchTypePerformance: [
            AdminMatchTypePerformance(
                name: "normal",
                label: "Hot-Match",
                emoji: "❤️",
                color: "#FF3366",
                requests: 44,
                matches: 18,
                ratePercent: 40.9
            ),
            AdminMatchTypePerformance(
                name: "hot",
                label: nil,
                emoji: nil,
                color: nil,
                requests: 20,
                matches: 4,
                ratePercent: 20
            ),
        ],
        feedbackCount: 16,
        feedbackAverage: 4.3,
        functionalityAverage: 4.4,
        easeOfUseAverage: 4.2,
        designAverage: 4.1,
        reuseAverage: 4.5,
        rejectedSendCount: 2,
        queueStallCount: 1,
        connectionLossCount: 3,
        deviceOutageCount: 1,
        peakInterval: "21:00–21:15",
        peakIntervalTotal: 28,
        eventDurationMinutes: 240,
        requestTypes: [
            AdminStatisticCount(name: "normal", count: 44),
            AdminStatisticCount(name: "Sondertyp \"A\"; Test", count: 20),
        ],
        actionTypes: [
            AdminStatisticCount(name: "bjob", count: 50),
            AdminStatisticCount(name: "hjob", count: 41),
        ],
        topParticipants: [
            AdminParticipantStatistic(number: "7", sent: 4, received: 5, matches: 2),
        ],
        timeline: (0..<30).map { index in
            AdminStatisticTimelinePoint(
                hour: String(format: "20:%02d", index * 2),
                requests: index,
                matches: index / 2,
                actions: index + 1
            )
        }
    )
}

func makeAdminLogEntry(
    eventType: String,
    actorRef: String = "7",
    subjectRef: String = "42",
    requestID: String = "12345678-ABCD-EF00-1111-222233334444",
    context: [String: LogContextValue] = [:]
) -> AdminEventLogEntry {
    AdminEventLogEntry(
        id: "log-1",
        occurredAt: "2026-09-13T20:00:00Z",
        receivedAt: "2026-09-13T20:00:01Z",
        severity: "info",
        category: "admin",
        eventType: eventType,
        actorType: "participant",
        actorRef: actorRef,
        subjectRef: subjectRef,
        deviceID: "device-1",
        requestID: requestID,
        status: "success",
        context: context
    )
}
