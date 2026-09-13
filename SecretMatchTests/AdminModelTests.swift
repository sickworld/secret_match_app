@testable import SecretMatch
import SwiftUI
import XCTest

@MainActor
final class ParticipantPresentationTests: XCTestCase {
    func testEveryGenderHasStableLabelsAndSymbols() {
        XCTAssertEqual(ParticipantGender.allCases.map(\.id), ["female", "male", "skip"])
        XCTAssertEqual(ParticipantGender.allCases.map(\.title), ["Frau", "Mann", "Lieber nicht"])
        XCTAssertEqual(ParticipantGender.allCases.map(\.symbol), ["♀", "♂", "–"])
    }

    func testAnnouncementTonesHaveStablePresentation() {
        XCTAssertEqual(EventAnnouncementTone.allCases.map(\.id), ["info", "highlight", "urgent"])
        XCTAssertEqual(EventAnnouncementTone.allCases.map(\.title), ["Info", "Highlight", "Dringend"])
        XCTAssertEqual(
            EventAnnouncementTone.allCases.map(\.systemImage),
            ["info.circle.fill", "sparkles", "exclamationmark.triangle.fill"]
        )
    }

    func testParticipantAndInteractionErrorsStayUserFriendly() {
        XCTAssertEqual(ParticipantLoginError.pinRequired.errorDescription, "Bitte persönliche PIN eingeben.")
        XCTAssertEqual(ParticipantLoginError.invalidCredentials.errorDescription, "Nummer oder PIN ist nicht gültig.")
        XCTAssertEqual(ParticipantLoginError.tooManyAttempts.errorDescription, "Zu viele Login-Versuche. Bitte kurz warten.")
        XCTAssertEqual(ParticipantLoginError.connectionUnavailable.errorDescription, "Match&Play ist gerade nicht erreichbar.")
        XCTAssertEqual(ParticipantLoginError.invalidResponse.errorDescription, "Der Login-Server antwortet nicht korrekt.")

        XCTAssertEqual(
            InteractionOptionsError.invalidTarget("7").errorDescription,
            "Die Nummer 007 ist für dieses Event nicht verfügbar."
        )
        XCTAssertEqual(
            InteractionOptionsError.connectivityUnavailable.errorDescription,
            "Die Auswahl wird gerade im Offline-Modus angezeigt."
        )
        XCTAssertEqual(
            InteractionOptionsError.unavailable.errorDescription,
            "Die Auswahl konnte gerade nicht angepasst werden."
        )
        XCTAssertEqual(ActionWithdrawalError(message: "Nicht möglich").errorDescription, "Nicht möglich")
    }
}

@MainActor
final class AdminDashboardSectionTests: XCTestCase {
    func testEverySectionHasNavigationMetadata() {
        XCTAssertEqual(AdminDashboardSection.allCases.count, 15)
        XCTAssertEqual(AdminDashboardSection.overview.title, "Aktionen")
        XCTAssertEqual(AdminDashboardSection.changelog.subtitle, "Neue Funktionen und Verbesserungen nachlesen")
        XCTAssertEqual(AdminDashboardSection.statistics.systemImage, "chart.bar.xaxis")
        XCTAssertFalse(AdminDashboardSection.featureSections.contains(.overview))
        XCTAssertEqual(Set(AdminDashboardSection.featureSections).count, AdminDashboardSection.featureSections.count)

        for section in AdminDashboardSection.allCases {
            XCTAssertFalse(section.id.isEmpty)
            XCTAssertFalse(section.title.isEmpty)
            XCTAssertFalse(section.subtitle.isEmpty)
            XCTAssertFalse(section.systemImage.isEmpty)
            _ = section.tint
        }
    }
}

@MainActor
final class AdminLogPresentationTests: XCTestCase {
    func testKnownGenericAndAdminTitlesUseReadableLabels() {
        XCTAssertEqual(makeAdminLogEntry(eventType: "interaction_delivered").title, "Aktion zugestellt")
        XCTAssertEqual(makeAdminLogEntry(eventType: "admin_action_created_success").title, "Admin: Aktion angelegt")
        XCTAssertEqual(
            makeAdminLogEntry(eventType: "admin_action_created_failed").title,
            "Admin: Aktion angelegt – fehlgeschlagen"
        )
        XCTAssertEqual(makeAdminLogEntry(eventType: "admin_unknown_success").title, "Admin-Änderung gespeichert")
        XCTAssertEqual(makeAdminLogEntry(eventType: "admin_unknown_failed").title, "Admin-Aktion fehlgeschlagen")
        XCTAssertEqual(makeAdminLogEntry(eventType: "custom_event_type").title, "Custom Event Type")
    }

    func testReferencesFormatNumbersAndLimitRequestID() {
        XCTAssertEqual(makeAdminLogEntry(eventType: "test").references, "007 → 042 ID 12345678")
        XCTAssertEqual(
            makeAdminLogEntry(eventType: "test", actorRef: "WordPress", subjectRef: "", requestID: "").references,
            "WordPress"
        )
    }

    func testCSVRowSortsContextKeysAndFormatsValues() {
        let entry = makeAdminLogEntry(
            eventType: "interaction_queued",
            context: ["zeta": .bool(false), "alpha": .number(2)]
        )

        XCTAssertEqual(entry.csvRow.count, 11)
        XCTAssertEqual(entry.csvRow.last, "alpha=2; zeta=nein")
    }
}

@MainActor
final class AdminStatusModelTests: XCTestCase {
    func testDeviceStatusUsesServerOnlineFlagAndQueueWording() {
        let status = AdminDeviceStatus(
            deviceID: "device-1",
            name: "Bar links",
            number: "7",
            batteryLevel: 87,
            batteryState: "charging",
            appVersion: "146",
            lastSeen: Int(Date().timeIntervalSince1970) - 20,
            online: false,
            queuedSendCount: 3,
            queuedBatchCount: 2,
            oldestPendingSeconds: 10,
            lastSuccessfulSyncAt: "jetzt",
            connectionState: "online"
        )

        XCTAssertEqual(status.id, "device-1")
        XCTAssertFalse(status.isOnline)
        XCTAssertEqual(status.lastSeenDescription, "gerade eben")
        XCTAssertEqual(status.queueSummary, "2 Versandvorgänge mit 3 Aktionen")
        XCTAssertEqual(status.queueWaitingDescription, "2 Versandvorgänge mit 3 Aktionen warten")
    }

    func testDeviceStatusFallsBackToHeartbeatAndCompositeID() {
        let now = Int(Date().timeIntervalSince1970)
        let recent = AdminDeviceStatus(
            deviceID: nil,
            name: nil,
            number: "42",
            batteryLevel: 50,
            batteryState: "unknown",
            appVersion: "146",
            lastSeen: now - 120,
            online: nil,
            queuedSendCount: nil,
            queuedBatchCount: nil,
            oldestPendingSeconds: nil,
            lastSuccessfulSyncAt: nil,
            connectionState: nil
        )
        let old = AdminDeviceStatus(
            deviceID: nil,
            name: nil,
            number: "42",
            batteryLevel: 50,
            batteryState: "unknown",
            appVersion: "146",
            lastSeen: now - 7_200,
            online: nil,
            queuedSendCount: 0,
            queuedBatchCount: 0,
            oldestPendingSeconds: nil,
            lastSuccessfulSyncAt: nil,
            connectionState: nil
        )

        XCTAssertEqual(recent.id, "42-146")
        XCTAssertTrue(recent.isOnline)
        XCTAssertEqual(recent.lastSeenDescription, "vor 2 Min.")
        XCTAssertFalse(old.isOnline)
        XCTAssertEqual(old.lastSeenDescription, "vor 2 Std.")
    }

    func testBillboardPresentationCoversEveryModeAndTimeRange() {
        let now = Int(Date().timeIntervalSince1970)
        let recent = AdminBillboardStatus(
            billboardID: "a",
            name: "TV",
            lastSeen: now - 30,
            online: true,
            width: 1920,
            height: 1080,
            mode: "normal"
        )
        let old = AdminBillboardStatus(
            billboardID: "b",
            name: "Beamer",
            lastSeen: now - 7_200,
            online: false,
            width: 0,
            height: 0,
            mode: "other"
        )

        XCTAssertEqual(recent.id, "a")
        XCTAssertEqual(recent.lastSeenDescription, "gerade eben")
        XCTAssertEqual(recent.modeLabel, "Normalbetrieb")
        XCTAssertEqual(old.lastSeenDescription, "vor 2 Std.")
        XCTAssertEqual(old.resolution, "Auflösung unbekannt")
        XCTAssertEqual(old.modeLabel, "Modus unbekannt")
    }
}

@MainActor
final class AdminContractDecodingTests: XCTestCase {
    func testDashboardDecodesNestedStatusObjects() throws {
        let dashboard = try JSONDecoder().decode(
            AdminDashboard.self,
            from: Data(
                """
                {
                  "active_participants": 12,
                  "allowed_participants": 120,
                  "matches": 8,
                  "requests": 14,
                  "actions": 27,
                  "latest_activity": "gerade eben",
                  "top_test_active": true,
                  "dummy_data_active": false,
                  "billboard_sessions": 2,
                  "billboard_rotation_seconds": 8,
                  "telegram_configured": true,
                  "apns_configured": true,
                  "apns_diagnostics": {
                    "configured": true,
                    "key_id_valid": true,
                    "team_id_valid": true,
                    "topic_valid": true,
                    "private_key_configured": true,
                    "private_key_readable": true,
                    "private_key_valid": true,
                    "key_source": "file",
                    "curl_available": true,
                    "curl_http2": true,
                    "openssl_available": true
                  },
                  "admin_push_devices": 1,
                  "plugin_version": "2026.09.13.1",
                  "wordpress_time": "2026-09-13T20:00:00Z",
                  "api_ok": true,
                  "billboard_online": true,
                  "billboard_last_seen": 123,
                  "billboard_width": 1920,
                  "billboard_height": 1080,
                  "billboard_mode": "top",
                  "billboard_url": "https://example.com/board",
                  "billboards": [{
                    "billboard_id": "board-1", "name": "TV", "last_seen": 123,
                    "online": true, "width": 1920, "height": 1080, "mode": "top"
                  }],
                  "top_people": [{"number": "7", "gender": "female"}],
                  "match_message_options": ["Hi"],
                  "devices": [{
                    "device_id": "device-1", "name": "Bar", "number": "7",
                    "battery_level": 80, "battery_state": "charging", "app_version": "146",
                    "last_seen": 123, "online": true, "queued_send_count": 2,
                    "queued_batch_count": 1, "oldest_pending_seconds": 5,
                    "last_successful_sync_at": "jetzt", "connection_state": "online"
                  }]
                }
                """.utf8
            )
        )

        XCTAssertEqual(dashboard.activeParticipants, 12)
        XCTAssertEqual(dashboard.requests, 14)
        XCTAssertEqual(dashboard.apnsDiagnostics?.keySourceDescription, "Schlüsseldatei")
        XCTAssertEqual(dashboard.billboards?.first?.resolution, "1920 × 1080")
        XCTAssertEqual(dashboard.topPeople?.first?.genderSymbol, "♀")
        XCTAssertEqual(dashboard.devices?.first?.queueSummary, "1 Versand mit 2 Aktionen")
    }

    func testAPNSKeySourceDescriptionsCoverLegacyAndMissingCases() throws {
        let base = """
        {"configured":false,"key_id_valid":false,"team_id_valid":false,"topic_valid":false,
        "private_key_configured":false,"private_key_readable":false,"private_key_valid":false,
        "key_source":"SOURCE","curl_available":false,"curl_http2":false,"openssl_available":false}
        """

        let inline = try JSONDecoder().decode(
            AdminAPNSDiagnostics.self,
            from: Data(base.replacingOccurrences(of: "SOURCE", with: "inline").utf8)
        )
        let missing = try JSONDecoder().decode(
            AdminAPNSDiagnostics.self,
            from: Data(base.replacingOccurrences(of: "SOURCE", with: "none").utf8)
        )

        XCTAssertEqual(inline.keySourceDescription, "Alte Inline-Konfiguration")
        XCTAssertEqual(missing.keySourceDescription, "Fehlt")
    }

    func testParticipantContractsDecodeDefaultsAndServerKeys() throws {
        let participants = try JSONDecoder().decode(
            AdminParticipants.self,
            from: Data(
                #"{"allowed":["7"],"active":[{"number":"7","last_activity":123}],"profiles":[{"number":"7","gender":"female"}],"pins":{"7":"12"}}"#.utf8
            )
        )
        let defaults = try JSONDecoder().decode(
            AdminParticipants.self,
            from: Data(#"{"allowed":[],"active":[]}"#.utf8)
        )

        XCTAssertEqual(participants.active.first?.id, "7-123")
        XCTAssertEqual(participants.profiles.first?.id, "7")
        XCTAssertEqual(participants.pins["7"], "12")
        XCTAssertTrue(defaults.profiles.isEmpty)
        XCTAssertTrue(defaults.pins.isEmpty)
    }

    func testResetAndRestoreResponsesDecodeNestedCounts() throws {
        let reset = try JSONDecoder().decode(
            EventResetResponse.self,
            from: Data(
                #"{"backup_created_at":"now","archive_id":"a1","archive_name":"Sommer","deleted":{"matches":2,"requests":3,"actions":4,"feedback":5,"event_log":6}}"#.utf8
            )
        )
        let restore = try JSONDecoder().decode(
            EventRestoreResponse.self,
            from: Data(
                #"{"restored_archive_id":"a1","restored_archive_name":"Sommer","safety_archive_id":"a2","safety_archive_name":"Sicherung","restored":{"matches":2,"requests":3,"actions":4,"profiles":5,"feedback":6,"event_log":7}}"#.utf8
            )
        )

        XCTAssertEqual(reset.deleted.eventLog, 6)
        XCTAssertEqual(reset.archiveName, "Sommer")
        XCTAssertEqual(restore.safetyArchiveName, "Sicherung")
        XCTAssertEqual(restore.restored.eventLog, 7)
    }

    func testStatisticsComputedValuesRemainStable() {
        let statistics = makeAdminStatisticsFixture()
        let participant = statistics.topParticipants?.first
        let timeline = statistics.timeline.first

        XCTAssertEqual(participant?.id, "7")
        XCTAssertEqual(participant?.activityTotal, 13)
        XCTAssertEqual(timeline?.id, "20:00")
        XCTAssertEqual(timeline?.total, 1)
        XCTAssertEqual(statistics.matchTypePerformance?.first?.id, "normal")
        XCTAssertEqual(statistics.requestTypes.first?.id, "normal")
    }
}
