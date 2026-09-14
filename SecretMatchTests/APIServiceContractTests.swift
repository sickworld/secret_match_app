import Foundation
@testable import SecretMatch
import SwiftUI
import XCTest

private final class MockURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "secret-match.de"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

@MainActor
final class APIServiceContractTests: XCTestCase {
    override func setUp() {
        super.setUp()
        Self.clearAdminPushDefaults()
        URLProtocol.registerClass(MockURLProtocol.self)
        MockURLProtocol.handler = { request in
            try Self.response(for: request, json: "{}")
        }
    }

    override func tearDown() {
        MockURLProtocol.handler = nil
        URLProtocol.unregisterClass(MockURLProtocol.self)
        Self.clearAdminPushDefaults()
        super.tearDown()
    }

    func testLoadsParticipantCatalogsAndActivityFromExpectedEndpoints() async throws {
        await resetService()
        MockURLProtocol.handler = { request in
            switch request.url?.path {
            case "/wp-json/secretmatch/v1/match-message-options":
                return try Self.response(for: request, json: #"{"options":["Hallo","Treffen?"]}"#)
            case "/wp-json/secretmatch/v1/action-types":
                return try Self.response(for: request, json: Self.actionDefinitionsJSON)
            case "/wp-json/secretmatch/v1/match-types":
                return try Self.response(for: request, json: Self.matchDefinitionsJSON)
            case "/wp-json/secretmatch/v1/interaction-options":
                XCTAssertEqual(request.url?.query, "target_number=42")
                return try Self.response(
                    for: request,
                    json: #"{"match_types":["normal"],"action_types":["bjob"],"profile_based":true}"#
                )
            case "/wp-json/secretmatch/v1/matches":
                return try Self.response(
                    for: request,
                    json: #"[{"id":"match-1","other":"42","type":"normal","message":"Hallo","created_at":"2026-09-13T20:00:00Z"}]"#
                )
            case "/wp-json/secretmatch/v1/interests":
                return try Self.response(
                    for: request,
                    json: #"[{"id":"interest-1","other":"23","type":"hot","message":null,"created_at":"2026-09-13T20:00:00Z"}]"#
                )
            case "/wp-json/secretmatch/v1/actions":
                return try Self.response(
                    for: request,
                    json: ##"[{"id":"action-1","sender_number":"7","receiver_number":"42","action_type":"bjob","request_id":"12345678-abcd-ef00-1111-222233334444","created_at":"2026-09-13T20:00:00Z","action_name":"Blow-Job","action_emoji":"💋","action_color":"#FF3366","action_category":"play","action_direction":"offer"}]"##
                )
            default:
                XCTFail("Unerwarteter Endpunkt: \(request.url?.absoluteString ?? "nil")")
                return try Self.response(for: request, statusCode: 404, json: "{}")
            }
        }

        let api = APIService.shared
        try await api.loadMatchMessageOptions()
        try await api.loadActionDefinitions()
        try await api.loadMatchDefinitions()
        let options = try await api.loadInteractionOptions(targetNumber: " 42 ")
        let matches = try await api.loadMatches()
        let interests = try await api.loadIncomingInterests()
        let actions = try await api.loadActions()

        XCTAssertEqual(api.matchMessageOptions, ["Hallo", "Treffen?"])
        XCTAssertEqual(api.actionDefinitions.map(\.id), ["bjob", "hjob"])
        XCTAssertEqual(api.matchDefinitions.map(\.id), ["normal", "hot"])
        XCTAssertEqual(options.matchTypes, ["normal"])
        XCTAssertEqual(options.actionTypes, ["bjob"])
        XCTAssertTrue(options.profileBased)
        XCTAssertEqual(matches.first?.other, "42")
        XCTAssertEqual(interests.first?.id, "interest-1")
        XCTAssertEqual(actions.first?.action_name, "Blow-Job")

        api.matches = matches
        api.actions = actions
        assertRenders(MatchView().environmentObject(api))
        for section in [ParticipantOverviewSection.matches, .interests, .actions] {
            assertRenders(
                ParticipantOverviewView(isPresented: .constant(true), selectedSection: section)
                    .environmentObject(api)
            )
        }
    }

    func testParticipantAuthenticationFeedbackAndInteractionSubmission() async throws {
        await resetService()
        MockURLProtocol.handler = { request in
            switch request.url?.path {
            case "/wp-json/secretmatch/v1/login":
                XCTAssertEqual(request.httpMethod, "POST")
                return try Self.response(
                    for: request,
                    json: #"{"number":"7","needs_pin":true,"needs_gender":true,"event_id":"event-contract-test"}"#
                )
            case "/wp-json/secretmatch/v1/pin":
                return try Self.response(for: request, json: "{}")
            case "/wp-json/secretmatch/v1/profile":
                return try Self.response(for: request, json: "{}")
            case "/wp-json/secretmatch/v1/feedback":
                XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
                return try Self.response(for: request, statusCode: 204, json: "")
            case "/wp-json/secretmatch/v1/action-types":
                return try Self.response(for: request, json: Self.actionDefinitionsJSON)
            case "/wp-json/secretmatch/v1/match-types":
                return try Self.response(for: request, json: Self.matchDefinitionsJSON)
            case "/wp-json/secretmatch/v1/match":
                return try Self.response(for: request, json: #"{"success":true,"data":"Match gespeichert"}"#)
            case "/wp-json/secretmatch/v1/actions":
                XCTAssertEqual(request.httpMethod, "POST")
                return try Self.response(for: request, json: #"{"message":"Aktion gespeichert"}"#)
            case let path? where path.hasPrefix("/wp-json/secretmatch/v1/actions/"):
                XCTAssertEqual(request.httpMethod, "DELETE")
                return try Self.response(for: request, json: "{}")
            case "/wp-json/secretmatch/v1/telemetry/events", "/wp-json/secretmatch/v1/logout", "/wp-json/secretmatch/v1/heartbeat":
                return try Self.response(for: request, json: "{}")
            default:
                XCTFail("Unerwarteter Endpunkt: \(request.url?.absoluteString ?? "nil")")
                return try Self.response(for: request, statusCode: 404, json: "{}")
            }
        }

        let api = APIService.shared
        let requirements = try await api.login(number: " 7 ", pin: "12")
        XCTAssertTrue(requirements.needsPin)
        XCTAssertTrue(requirements.needsGender)
        XCTAssertEqual(api.number, "7")

        try await api.setParticipantPIN("12", confirmation: "12")
        try await api.submitParticipantGender(.female)
        try await api.submitFeedback(rating: 5, functionalityRating: 4, easeOfUseRating: 5, designRating: 4)
        try await api.loadActionDefinitions()
        try await api.loadMatchDefinitions()
        api.isLoggedIn = true

        let submission = try await api.submitInteractions(
            targetNumber: "42",
            types: ["normal", "bjob"],
            message: " Hallo "
        )

        XCTAssertEqual(submission.messages, ["Match gespeichert", "Aktion gespeichert"])
        XCTAssertEqual(submission.queuedCount, 0)
        XCTAssertEqual(submission.actionRequestIDs.count, 1)
        XCTAssertEqual(api.interactionDeliveryStatus, .delivered(count: 2))

        try await api.withdrawAction(requestID: submission.actionRequestIDs[0].uuidString)
        await XCTAssertThrowsErrorAsync {
            try await api.withdrawAction(requestID: "keine-uuid")
        }

        api.number = ""
        api.logout()
    }

    func testParticipantAPIMapsInvalidTargetAndAuthenticationErrors() async throws {
        await resetService()
        let api = APIService.shared
        MockURLProtocol.handler = { request in
            switch request.url?.path {
            case "/wp-json/secretmatch/v1/interaction-options":
                return try Self.response(for: request, statusCode: 400, json: #"{"code":"invalid_target"}"#)
            case "/wp-json/secretmatch/v1/login":
                return try Self.response(for: request, statusCode: 401, json: #"{"code":"invalid_credentials"}"#)
            default:
                return try Self.response(for: request, json: "{}")
            }
        }

        do {
            _ = try await api.loadInteractionOptions(targetNumber: "99")
            XCTFail("Ungültige Zielnummer wurde akzeptiert")
        } catch InteractionOptionsError.invalidTarget(let number) {
            XCTAssertEqual(number, "99")
        } catch {
            XCTFail("Falscher Fehler: \(error)")
        }

        do {
            _ = try await api.login(number: "7", pin: "00")
            XCTFail("Ungültige Zugangsdaten wurden akzeptiert")
        } catch ParticipantLoginError.invalidCredentials {
            // Expected.
        } catch {
            XCTFail("Falscher Fehler: \(error)")
        }
    }

    func testParticipantSubmissionMapsPermanentFailuresAndWithdrawsQueuedRetry() async throws {
        await resetService()
        var serverErrorCode = "invalid_target"
        MockURLProtocol.handler = { request in
            switch request.url?.path {
            case "/wp-json/secretmatch/v1/action-types":
                return try Self.response(for: request, json: Self.actionDefinitionsJSON)
            case "/wp-json/secretmatch/v1/match-types":
                return try Self.response(for: request, json: Self.matchDefinitionsJSON)
            case "/wp-json/secretmatch/v1/match":
                return try Self.response(
                    for: request,
                    statusCode: 422,
                    json: #"{"code":"\#(serverErrorCode)"}"#
                )
            case "/wp-json/secretmatch/v1/actions":
                return try Self.response(for: request, statusCode: 503, json: "{}")
            case "/wp-json/secretmatch/v1/telemetry/events", "/wp-json/secretmatch/v1/heartbeat":
                return try Self.response(for: request, json: "{}")
            default:
                return try Self.response(for: request, json: "{}")
            }
        }

        let api = APIService.shared
        try await api.loadActionDefinitions()
        try await api.loadMatchDefinitions()
        api.number = "7"
        api.isLoggedIn = true

        let expectedMessages = [
            ("invalid_target", "Die Nummer 042 gibt es bei diesem Event nicht."),
            ("invalid", "Bitte prüfe die Zielnummer und deine Auswahl."),
            ("message_too_long", "Deine Nachricht ist zu lang."),
            ("request_id_conflict", "Diese Sendung konnte nicht eindeutig zugeordnet werden."),
            ("unknown", "Das hat gerade nicht geklappt."),
        ]
        for (code, expectedMessagePrefix) in expectedMessages {
            serverErrorCode = code
            await XCTAssertThrowsErrorAsync {
                _ = try await api.submitInteractions(targetNumber: "42", types: ["normal"])
            }
            XCTAssertTrue(api.interactionDeliveryErrorMessage?.hasPrefix(expectedMessagePrefix) == true)
        }

        let queued = try await api.submitInteractions(targetNumber: "42", types: ["bjob"])
        XCTAssertEqual(queued.queuedCount, 1)
        XCTAssertEqual(queued.actionRequestIDs.count, 1)
        XCTAssertEqual(api.interactionDeliveryStatus, .queued(count: 1))

        let withdrawn = try await api.withdrawActions(requestIDs: queued.actionRequestIDs)
        XCTAssertEqual(withdrawn, 1)
        XCTAssertEqual(api.queuedSendCount, 0)
        XCTAssertNil(api.interactionDeliveryStatus)

        api.applicationDidEnterBackground()
        api.number = ""
        api.logout()
    }

    func testAdminLoginMapsCredentialServerAndPayloadFailures() async {
        await resetService()
        let api = APIService.shared

        MockURLProtocol.handler = { request in
            try Self.response(for: request, statusCode: 401, json: #"{"code":"invalid_credentials"}"#)
        }
        guard case .invalidCredentials = await api.adminLogin(password: "falsch") else {
            return XCTFail("HTTP 401 wurde nicht als ungültige Anmeldung erkannt")
        }

        MockURLProtocol.handler = { request in
            try Self.response(for: request, statusCode: 500, json: "{}")
        }
        guard case .connectionFailed = await api.adminLogin(password: "test") else {
            return XCTFail("HTTP 500 wurde nicht als Verbindungsfehler erkannt")
        }

        MockURLProtocol.handler = { request in
            try Self.response(for: request, json: #"{"unexpected":true}"#)
        }
        guard case .connectionFailed = await api.adminLogin(password: "test") else {
            return XCTFail("Eine ungültige Login-Antwort wurde akzeptiert")
        }
    }

    func testAdminFeedbackSupportsEnvelopesAndMapsResponseErrors() async throws {
        await resetService()
        let api = APIService.shared
        MockURLProtocol.handler = { request in
            try Self.response(for: request, json: #"{"token":"feedback-contract-token"}"#)
        }
        guard case .success = await api.adminLogin(password: "test") else {
            return XCTFail("Admin-Login für Feedback-Verträge fehlgeschlagen")
        }

        var statusCode = 200
        var responseJSON = #"{"feedback":[{"id":"wrapped","rating":"5","created_at":"jetzt"}]}"#
        MockURLProtocol.handler = { request in
            try Self.response(for: request, statusCode: statusCode, json: responseJSON)
        }

        try await api.loadAdminFeedback()
        XCTAssertEqual(api.adminFeedback.map(\.id), ["wrapped"])

        responseJSON = #"{"data":[{"id":"legacy","rating":4,"created_at":"vorhin"}]}"#
        try await api.loadAdminFeedback()
        XCTAssertEqual(api.adminFeedback.map(\.id), ["legacy"])

        responseJSON = #"{"unknown":[]}"#
        do {
            try await api.loadAdminFeedback()
            XCTFail("Unbekanntes Feedback-Format wurde akzeptiert")
        } catch AdminFeedbackLoadError.invalidPayload {
            // Expected.
        } catch {
            XCTFail("Falscher Fehler für unbekanntes Feedback-Format: \(error)")
        }

        statusCode = 503
        do {
            try await api.loadAdminFeedback()
            XCTFail("Feedback-Serverfehler wurde akzeptiert")
        } catch AdminFeedbackLoadError.server(let receivedStatusCode) {
            XCTAssertEqual(receivedStatusCode, 503)
        } catch {
            XCTFail("Falscher Fehler für Feedback-Serverfehler: \(error)")
        }

        statusCode = 401
        do {
            try await api.loadAdminFeedback()
            XCTFail("Abgelaufene Feedback-Sitzung wurde akzeptiert")
        } catch AdminFeedbackLoadError.sessionExpired {
            XCTAssertFalse(api.isAdmin)
        } catch {
            XCTFail("Falscher Fehler für abgelaufene Feedback-Sitzung: \(error)")
        }
    }

    func testAdminReadAndMutationContracts() async throws {
        await resetService()
        MockURLProtocol.handler = { request in
            let path = request.url?.path ?? ""
            switch (path, request.httpMethod ?? "GET") {
            case ("/wp-json/secretmatch/v1/admin/login", "POST"):
                return try Self.response(for: request, json: #"{"token":"contract-test-token"}"#)
            case ("/wp-json/secretmatch/v1/admin/actions", "GET"):
                return try Self.response(for: request, json: Self.adminActionsJSON)
            case ("/wp-json/secretmatch/v1/admin/action-types", "GET"):
                return try Self.response(for: request, json: Self.actionDefinitionsJSON)
            case ("/wp-json/secretmatch/v1/admin/match-types", "GET"):
                return try Self.response(for: request, json: Self.matchDefinitionsJSON)
            case ("/wp-json/secretmatch/v1/admin/matches", "GET"):
                return try Self.response(for: request, json: Self.adminMatchesJSON)
            case ("/wp-json/secretmatch/v1/admin/requests", "GET"):
                return try Self.response(for: request, json: Self.adminRequestsJSON)
            case ("/wp-json/secretmatch/v1/admin/feedback", "GET"):
                return try Self.response(for: request, json: Self.adminFeedbackJSON)
            case ("/wp-json/secretmatch/v1/admin/dashboard", "GET"):
                return try Self.response(for: request, json: Self.adminDashboardJSON)
            case ("/wp-json/secretmatch/v1/admin/event-announcements", "GET"):
                return try Self.response(for: request, json: Self.announcementsJSON)
            case ("/wp-json/secretmatch/v1/admin/credentials", "GET"):
                return try Self.response(for: request, json: Self.credentialsJSON)
            case ("/wp-json/secretmatch/v1/admin/participants", "GET"):
                return try Self.response(for: request, json: Self.participantsJSON)
            case ("/wp-json/secretmatch/v1/admin/screensaver-content", "GET"):
                return try Self.response(for: request, json: Self.screensaverJSON)
            case ("/wp-json/secretmatch/v1/admin/screensaver-settings", "GET"):
                return try Self.response(for: request, json: #"{"idle_seconds":75}"#)
            case ("/wp-json/secretmatch/v1/admin/number-overview", "GET"):
                XCTAssertEqual(request.url?.query, "number=7")
                return try Self.response(for: request, json: Self.numberOverviewJSON)
            case ("/wp-json/secretmatch/v1/admin/delivery-diagnostics", "GET"):
                return try Self.response(for: request, json: Self.deliveryDiagnosticsJSON)
            case ("/wp-json/secretmatch/v1/admin/event-log", "GET"):
                return try Self.response(for: request, json: Self.eventLogJSON)
            case ("/wp-json/secretmatch/v1/admin/event-log/examples", "POST"):
                return try Self.response(for: request, json: #"{"created":3,"available":3}"#)
            case ("/wp-json/secretmatch/v1/admin/billboard-access", "POST"):
                return try Self.response(for: request, json: #"{"url":"https://secret-match.de/secretmatch-board/?token=test","expires_in":3600}"#)
            case (let value, "PATCH") where value.hasSuffix("/participants/7"):
                return try Self.response(for: request, json: #"{"pin_reset":true}"#)
            case (let value, "DELETE") where value.hasSuffix("/credentials/credential-1"):
                return try Self.response(for: request, json: #"{"revoked_sessions":1,"current_session_revoked":false}"#)
            case ("/wp-json/secretmatch/v1/admin/participants/range", "PUT"):
                return try Self.response(for: request, json: #"{"target_max":120,"allowed_count":120,"added_count":20,"removed_count":0}"#)
            case ("/wp-json/secretmatch/v1/screensaver-settings", "GET"):
                return try Self.response(for: request, json: #"{"idle_seconds":75}"#)
            case ("/wp-json/secretmatch/v1/screensaver-content", "GET"):
                return try Self.response(for: request, json: "[]")
            default:
                if path.hasPrefix("/wp-json/secretmatch/v1/admin/") {
                    XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer contract-test-token")
                }
                return try Self.response(for: request, json: "{}")
            }
        }

        let api = APIService.shared
        guard case .success = await api.adminLogin(password: "test") else {
            return XCTFail("Admin-Login fehlgeschlagen")
        }

        try await api.loadAdminActions()
        try await api.loadAdminActionDefinitions()
        try await api.loadAdminMatchDefinitions()
        try await api.loadAdminMatches()
        try await api.loadAdminMatchRequests()
        try await api.loadAdminFeedback()
        try await api.loadAdminDashboard()
        try await api.loadAdminEventAnnouncements()
        try await api.loadAdminCredentials()
        try await api.loadAdminParticipants()
        try await api.loadAdminScreensaverContent()
        let overview = try await api.loadAdminNumberOverview(number: " 7 ")
        let diagnostics = try await api.loadDeliveryDiagnostics(sourceNumber: "7", targetNumber: "42")
        let logCount = try await api.loadAdminEventLog(severity: "info", category: "admin", search: " Test ")
        let examples = try await api.createAdminEventLogExamples()
        let accessURL = try await api.createBillboardAccessURL(name: "Haupt-TV")

        XCTAssertTrue(api.isAdmin)
        XCTAssertEqual(api.adminActions.count, 1)
        XCTAssertEqual(api.adminMatches.count, 1)
        XCTAssertEqual(api.adminMatchRequests.count, 1)
        XCTAssertEqual(api.adminFeedback.count, 1)
        XCTAssertEqual(api.adminDashboard?.pluginVersion, "2026.09.13.1")
        XCTAssertEqual(api.adminEventAnnouncements.first?.message, "Willkommen")
        XCTAssertEqual(api.adminCredentials.first?.name, "Eventleitung")
        XCTAssertEqual(api.adminParticipants.allowed, ["7", "42"])
        XCTAssertEqual(api.adminScreensaverItems.first?.title, "Sponsor")
        XCTAssertEqual(api.screensaverIdleSeconds, 75)
        XCTAssertEqual(overview.counts.matches, 2)
        XCTAssertEqual(diagnostics.first?.state, "delivered")
        XCTAssertEqual(logCount, 1)
        XCTAssertEqual(examples.created, 3)
        XCTAssertEqual(accessURL.host, "secret-match.de")

        assertRenders(AdminEventAnnouncementsView().environmentObject(api))
        assertRenders(AdminScreensaverMediaView().environmentObject(api))
        assertRenders(
            AdminActionCatalogView(isPresented: .constant(true))
                .environmentObject(api)
        )
        assertRenders(
            AdminMatchCatalogView(isPresented: .constant(true))
                .environmentObject(api)
        )

        let action = try XCTUnwrap(api.actionDefinitions.first)
        let match = try XCTUnwrap(api.matchDefinitions.first)
        try await api.saveAdminActionDefinition(action, isNew: true)
        try await api.saveAdminActionDefinition(action, isNew: false)
        try await api.deleteAdminActionDefinition(id: action.id)
        try await api.saveAdminMatchDefinition(match, isNew: true)
        try await api.saveAdminMatchDefinition(match, isNew: false)
        try await api.deleteAdminMatchDefinition(id: match.id)
        try await api.createAdminAction(senderNumber: "7", receiverNumber: "42", type: "bjob")
        try await api.updateAdminAction(id: "action-1", senderNumber: "7", receiverNumber: "42", type: "hjob")
        try await api.createAdminMatch(numberA: "7", numberB: "42", type: "normal")
        try await api.updateAdminMatch(id: "match-1", numberA: "7", numberB: "42", type: "hot")
        try await api.updateAdminMatchRequest(id: "request-1", participantA: "7", participantB: "42", type: "normal", message: "Hallo")
        try await api.createAdminParticipant(number: "99")
        let range = try await api.reconcileParticipantRange(targetMax: 120, confirmation: "120")
        XCTAssertEqual(range.addedCount, 20)
        try await api.updateParticipantGender(number: "7", gender: .female)
        try await api.updateParticipantGender(number: "7", gender: nil)
        try await api.updateParticipantPIN(number: "7", pin: "12")
        try await api.resetParticipantPIN(number: "7")
        try await api.updateMatchMessageOptions(["Hallo", "Treffen?"])
        try await api.createAdminEventAnnouncement(message: " Willkommen ", tone: "info", enabled: true, startsAt: nil, endsAt: nil)
        try await api.updateAdminEventAnnouncement(id: "notice-1", message: "Update", tone: "urgent", enabled: false, startsAt: 100, endsAt: 200)
        try await api.deleteAdminEventAnnouncement(id: "notice-1")
        try await api.createAdminCredential(name: "Zweite Leitung", password: "sicher")
        let deletion = try await api.deleteAdminCredential(id: "credential-1")
        XCTAssertEqual(deletion.revokedSessions, 1)
        try await api.updateAdminDeviceName(id: "device-1", name: "Bar links")
        try await api.deleteAdminDevice(id: "device-1")
        try await api.updateAdminBillboardName(id: "board-1", name: "TV")
        try await api.deleteAdminBillboard(id: "board-1")
        try await api.updateAdminScreensaverSettings(idleSeconds: 3)
        try await api.updateAdminScreensaverItem(id: "123e4567-e89b-12d3-a456-426614174000", title: "Sponsor 2", showInScreensaver: true, showAsSponsor: false, useLightBackground: true, displaySeconds: 10, enabled: true, sortOrder: 2)
        try await api.deleteAdminScreensaverItem(id: "123e4567-e89b-12d3-a456-426614174000")
        try await api.controlBillboard(action: "top", seconds: 8)
        try await api.deleteAdminAction(id: "action-1")
        try await api.deleteAdminMatch(id: "match-1")
        try await api.deleteAdminMatchRequest(id: "request-1")
        try await api.deleteAdminFeedback(id: "feedback-1")
        try await api.logoutParticipant(number: "7")
        try await api.blockParticipant(number: "42")

        await api.registerAdminPushToken(String(repeating: "a", count: 64), environment: "sandbox")
        await api.unregisterAdminPushToken()

        api.applicationDidEnterBackground()
        Self.clearAdminPushDefaults()
        let logoutCompleted = expectation(description: "Admin-Logout abgeschlossen")
        MockURLProtocol.handler = { request in
            switch request.url?.path {
            case "/wp-json/secretmatch/v1/admin/logout":
                XCTAssertEqual(request.httpMethod, "POST")
                logoutCompleted.fulfill()
                return try Self.response(for: request, json: "{}")
            case "/wp-json/secretmatch/v1/heartbeat":
                return try Self.response(for: request, json: "{}")
            default:
                XCTFail("Unerwarteter Endpunkt beim Admin-Logout: \(request.url?.absoluteString ?? "nil")")
                return try Self.response(for: request, statusCode: 404, json: "{}")
            }
        }
        api.logout()
        await fulfillment(of: [logoutCompleted], timeout: 2)
    }

    private static func response(
        for request: URLRequest,
        statusCode: Int = 200,
        json: String
    ) throws -> (HTTPURLResponse, Data) {
        let url = try XCTUnwrap(request.url)
        let response = try XCTUnwrap(
            HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )
        )
        return (response, Data(json.utf8))
    }

    private func resetService() async {
        MockURLProtocol.handler = { request in
            try Self.response(for: request, json: "{}")
        }
        let api = APIService.shared
        api.number = ""
        api.logout()
        try? await Task.sleep(for: .milliseconds(100))
    }

    private static func clearAdminPushDefaults() {
        UserDefaults.standard.removeObject(forKey: "secretmatch.admin-push-device-token")
        UserDefaults.standard.removeObject(forKey: "secretmatch.admin-push-environment")
    }

    private func assertRenders<Content: View>(
        _ content: Content,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for size in [CGSize(width: 1_024, height: 768), CGSize(width: 768, height: 1_024)] {
            let renderer = ImageRenderer(
                content: content.frame(width: size.width, height: size.height)
            )
            renderer.scale = 1
            XCTAssertNotNil(renderer.uiImage, file: file, line: line)
        }
    }

    private static let actionDefinitionsJSON = ##"{"actions":[{"id":"hjob","name":"Hand-Job","emoji":"✋","color":"#E6923E","category":"play","direction":"offer","target_gender":"any","enabled":true,"sort_order":20},{"id":"bjob","name":"Blow-Job","emoji":"💋","color":"#3E9ED6","category":"play","direction":"offer","target_gender":"male","enabled":true,"sort_order":10}]}"##
    private static let matchDefinitionsJSON = ##"{"matches":[{"id":"hot","name":"Fuck-Match","emoji":"🍆","color":"#8E63D2","enabled":true,"sort_order":20},{"id":"normal","name":"Hot-Match","emoji":"❤️","color":"#E83E8C","enabled":true,"sort_order":10}]}"##
    private static let adminActionsJSON = ##"[{"id":"action-1","sender_number":"7","receiver_number":"42","action_type":"bjob","created_at":"2026-09-13T20:00:00Z","action_name":"Blow-Job","action_emoji":"💋","action_color":"#FF3366","action_category":"play","action_direction":"offer"}]"##
    private static let adminMatchesJSON = #"[{"id":"match-1","number_a":"7","number_b":"42","type":"normal","created_at":"2026-09-13T20:00:00Z"}]"#
    private static let adminRequestsJSON = #"[{"id":"request-1","participant_a":"7","participant_b":"42","type":"normal","message":"Hallo","created_at":"2026-09-13T20:00:00Z","is_matched":false}]"#
    private static let adminFeedbackJSON = #"[{"id":"feedback-1","rating":"5","functionality_rating":4,"ease_of_use_rating":"5","design_rating":4,"created_at":"2026-09-13T20:00:00Z"}]"#
    private static let adminDashboardJSON = #"{"active_participants":12,"allowed_participants":120,"matches":22,"requests":64,"actions":91,"latest_activity":"gerade eben","top_test_active":true,"dummy_data_active":false,"billboard_sessions":2,"billboard_rotation_seconds":8,"telegram_configured":true,"plugin_version":"2026.09.13.1","wordpress_time":"2026-09-13T20:00:00Z","api_ok":true}"#
    private static let announcementsJSON = #"[{"id":"notice-1","message":"Willkommen","tone":"highlight","enabled":true,"starts_at":100,"ends_at":200,"created_at":50,"updated_at":75,"live":true}]"#
    private static let credentialsJSON = #"{"credentials":[{"id":"credential-1","name":"Eventleitung","created_at":123}],"standard_credential_active":true}"#
    private static let participantsJSON = #"{"allowed":["7","42"],"active":[{"number":"7","last_activity":123}],"profiles":[{"number":"7","gender":"female"}],"pins":{"7":"12"}}"#
    private static let screensaverJSON = #"[{"id":"123e4567-e89b-12d3-a456-426614174000","attachment_id":17,"title":"Sponsor","image_url":"https://secret-match.de/sponsor.png","show_in_screensaver":true,"show_as_sponsor":false,"use_light_background":true,"display_seconds":12,"enabled":true,"sort_order":30,"revision":2,"updated_at":123456}]"#
    private static let eventLogJSON = #"[{"id":"log-1","occurred_at":"2026-09-13T20:00:00Z","received_at":"2026-09-13T20:00:01Z","severity":"info","category":"admin","event_type":"admin_login_success","actor_type":"admin","actor_ref":"Eventleitung","subject_ref":"","device_id":"device-1","request_id":"12345678-abcd-ef00-1111-222233334444","status":"success","context":{"kind":"login"}}]"#
    private static let numberOverviewJSON = #"{"number":"7","allowed":true,"active":true,"last_activity":123,"gender":"female","pin_configured":true,"counts":{"sent_requests":3,"received_requests":4,"sent_actions":5,"received_actions":6,"matches":2},"recent_activity":[{"id":"activity-1","kind":"match","direction":"outgoing","counterpart":"42","type":"normal","created_at":"2026-09-13T20:00:00Z","has_message":true}],"devices":[],"recent_logs":[]}"#
    private static let deliveryDiagnosticsJSON = #"[{"id":"diagnostic-1","source_number":"7","target_number":"42","kind":"match","interaction_type":"normal","state":"delivered","retry_count":0,"error_code":"","created_at":"2026-09-13T20:00:00Z","updated_at":"2026-09-13T20:00:01Z","steps":[]}]"#
}

private func XCTAssertThrowsErrorAsync(
    _ expression: () async throws -> Void,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        try await expression()
        XCTFail("Erwarteter Fehler wurde nicht ausgelöst", file: file, line: line)
    } catch {
        // Expected.
    }
}
