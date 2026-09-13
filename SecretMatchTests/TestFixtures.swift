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

func makeAdminDashboardFixture() -> AdminDashboard {
    AdminDashboard(
        activeParticipants: 12,
        allowedParticipants: 120,
        matches: 22,
        requests: 64,
        actions: 91,
        latestActivity: "gerade eben",
        topTestActive: true,
        dummyDataActive: true,
        billboardSessions: 2,
        billboardRotationSeconds: 8,
        telegramConfigured: true,
        apnsConfigured: true,
        apnsDiagnostics: AdminAPNSDiagnostics(
            configured: true,
            keyIDValid: true,
            teamIDValid: true,
            topicValid: true,
            privateKeyConfigured: true,
            privateKeyReadable: true,
            privateKeyValid: true,
            keySource: "file",
            curlAvailable: true,
            curlHTTP2: true,
            opensslAvailable: true
        ),
        adminPushDevices: 1,
        pluginVersion: "2026.09.13.1",
        wordpressTime: "2026-09-13T20:00:00Z",
        apiOK: true,
        billboardOnline: true,
        billboardLastSeen: Int(Date().timeIntervalSince1970) - 20,
        billboardWidth: 1_920,
        billboardHeight: 1_080,
        billboardMode: "top",
        billboardURL: "https://example.com/board",
        billboards: [
            AdminBillboardStatus(
                billboardID: "board-1",
                name: "Haupt-TV",
                lastSeen: Int(Date().timeIntervalSince1970) - 20,
                online: true,
                width: 1_920,
                height: 1_080,
                mode: "top"
            ),
        ],
        topPeople: [TopPerson(number: "7", gender: "female")],
        matchMessageOptions: ["Hallo", "Treffen wir uns?"],
        devices: [makeAdminDeviceFixture()]
    )
}

func makeAdminDeviceFixture() -> AdminDeviceStatus {
    AdminDeviceStatus(
        deviceID: "device-1",
        name: "Bar links",
        number: "7",
        batteryLevel: 82,
        batteryState: "charging",
        appVersion: "148",
        lastSeen: Int(Date().timeIntervalSince1970) - 20,
        online: true,
        queuedSendCount: 2,
        queuedBatchCount: 1,
        oldestPendingSeconds: 12,
        lastSuccessfulSyncAt: "2026-09-13T20:00:00Z",
        connectionState: "online"
    )
}

func makeAdminNumberOverviewFixture() -> AdminNumberOverview {
    AdminNumberOverview(
        number: "7",
        allowed: true,
        active: true,
        lastActivity: 123,
        gender: "female",
        pinConfigured: true,
        counts: AdminNumberCounts(
            sentRequests: 3,
            receivedRequests: 4,
            sentActions: 5,
            receivedActions: 6,
            matches: 2
        ),
        recentActivity: [
            AdminNumberActivity(id: "activity-match", kind: "match", direction: "sent", counterpart: "42", type: "normal", createdAt: "2026-09-13T20:00:00Z", hasMessage: true),
            AdminNumberActivity(id: "activity-request", kind: "request", direction: "received", counterpart: "23", type: "hot", createdAt: "2026-09-13T19:00:00Z", hasMessage: false),
            AdminNumberActivity(id: "activity-action", kind: "action", direction: "sent", counterpart: "11", type: "bjob", createdAt: "2026-09-13T18:00:00Z", hasMessage: false),
        ],
        devices: [makeAdminDeviceFixture()],
        recentLogs: [
            makeAdminLogEntry(eventType: "interaction_delivered"),
            AdminEventLogEntry(
                id: "log-error",
                occurredAt: "2026-09-13T20:01:00Z",
                receivedAt: "2026-09-13T20:01:01Z",
                severity: "error",
                category: "delivery",
                eventType: "interaction_rejected",
                actorType: "participant",
                actorRef: "7",
                subjectRef: "42",
                deviceID: "device-1",
                requestID: "87654321-abcd-ef00-1111-222233334444",
                status: "failed",
                context: [:]
            ),
        ]
    )
}

func makeDeliveryDiagnosticsFixtures() -> [AdminDeliveryDiagnostic] {
    let states = ["delivered", "rejected", "retrying", "sending", "queued", "withdrawn", "unknown"]
    return states.enumerated().map { index, state in
        AdminDeliveryDiagnostic(
            id: "diagnostic-\(index)",
            sourceNumber: "7",
            targetNumber: "42",
            kind: "match",
            interactionType: index == states.count - 1 ? "" : (index.isMultiple(of: 2) ? "normal" : "bjob"),
            state: state,
            retryCount: index,
            errorCode: index.isMultiple(of: 2) ? "" : "http_500",
            createdAt: "2026-09-13T20:00:00Z",
            updatedAt: "2026-09-13T20:00:01Z",
            steps: [
                makeAdminLogEntry(eventType: "interaction_delivered"),
                makeAdminLogEntry(eventType: "interaction_rejected"),
                makeAdminLogEntry(eventType: "interaction_retry_scheduled"),
                makeAdminLogEntry(eventType: "action_withdrawn_success"),
            ]
        )
    }
}
