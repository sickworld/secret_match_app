import Foundation
import Combine
import Network
import SwiftUI
import UIKit

@MainActor
class APIService: ObservableObject {
    static let shared = APIService()
    private static let pendingInteractionsKey = "secretmatch.pending-interactions.v1"
    private static let pendingInteractionLifetime: TimeInterval = 24 * 60 * 60
    private static let pendingTelemetryKey = "secretmatch.pending-telemetry.v1"
    private static let telemetryLifetime: TimeInterval = 7 * 24 * 60 * 60
    private static let lastSuccessfulSyncKey = "secretmatch.last-successful-sync"
    private static let installationIDKey = "secretmatch.installation-id"
    private static let eventIDKey = "secretmatch.event-id"
    private static let adminPushTokenKey = "secretmatch.admin-push-device-token"
    private static let adminPushEnvironmentKey = "secretmatch.admin-push-environment"

    private init() {
        pendingInteractions = Self.loadPendingInteractions()
        pendingTelemetryEvents = Self.loadPendingTelemetryEvents()
        removeExpiredPendingInteractions()
        removeExpiredTelemetryEvents()

        if let savedAdminToken = AdminSessionStore.loadToken(), !savedAdminToken.isEmpty {
            adminToken = savedAdminToken
            hasSavedAdminSession = true
        }

        startNetworkMonitoring()
    }

    @Published var isLoggedIn: Bool = false
    @Published var number: String = ""
    @Published var matches: [Match] = []
    @Published var actions: [SecretAction] = []
    @Published var isAdmin: Bool = false
    @Published private(set) var hasSavedAdminSession: Bool = false
    @Published var adminActions: [AdminAction] = []
    @Published var adminMatches: [AdminMatch] = []
    @Published var adminMatchRequests: [AdminMatchRequest] = []
    @Published var adminFeedback: [AdminFeedback] = []
    @Published var adminEventLog: [AdminEventLogEntry] = []
    @Published var adminStatistics: AdminStatisticsResponse?
    @Published var adminDashboard: AdminDashboard?
    @Published var adminParticipants = AdminParticipants(allowed: [], active: [])
    @Published private(set) var queuedSendCount = 0
    @Published private(set) var isRetryingQueuedSends = false
    @Published private(set) var connectionState: ConnectionState = .checking
    @Published private(set) var isCheckingConnection = false
    @Published private(set) var matchMessageOptions: [String] = []
    private var adminToken: String?
    private let baseURL = URL(string: "https://secret-match.de/wp-json/secretmatch/v1")!
    private var pendingInteractions: [PendingInteraction]
    private var pendingTelemetryEvents: [PendingTelemetryEvent]
    private var isNetworkAvailable = true
    private var isProcessingSendQueue = false
    private var isFlushingTelemetry = false
    private var isApplicationActive = false
    private var retryTask: Task<Void, Never>?
    private var connectionPollingTask: Task<Void, Never>?
    private var heartbeatTask: Task<Void, Never>?
    private let networkMonitor = NWPathMonitor()
    private let networkMonitorQueue = DispatchQueue(label: "de.secret-match.send-queue.network")

    func login(number: String, pin: String) async throws -> ParticipantLoginRequirements {
        if isAdmin { return ParticipantLoginRequirements(needsPin: false, needsGender: false) }
        await waitForSendQueueToFinish()
        await retryPendingSendsForPreviousSession()
        await flushTelemetryEvents(allowsLoggedOutSession: true)

        let normalizedNumber = number.normalizedEventNumber
        let url = baseURL.appendingPathComponent("login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = formBody(["secretmatch_number": normalizedNumber, "secretmatch_pin": pin])
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ParticipantLoginError.invalidResponse
        }
        guard http.statusCode == 200 else {
            let responseError = try? JSONDecoder().decode(ParticipantLoginErrorResponse.self, from: data)
            switch responseError?.code {
            case "pin_required": throw ParticipantLoginError.pinRequired
            case "too_many_attempts": throw ParticipantLoginError.tooManyAttempts
            case "invalid_credentials": throw ParticipantLoginError.invalidCredentials
            default: throw ParticipantLoginError.invalidResponse
            }
        }

        let result = try JSONDecoder().decode(ParticipantLoginResponse.self, from: data)
        handleEventBoundary(result.eventID)
        self.number = result.number ?? normalizedNumber
        updateQueuedSendCount()
        return ParticipantLoginRequirements(needsPin: result.needsPin, needsGender: result.needsGender)
    }

    func setParticipantPIN(_ pin: String, confirmation: String) async throws {
        let url = baseURL.appendingPathComponent("pin")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = formBody(["pin": pin, "pin_confirmation": confirmation])
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }

    func submitParticipantGender(_ gender: ParticipantGender) async throws {
        let url = baseURL.appendingPathComponent("profile")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = formBody(["gender": gender.rawValue])
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }

    func submitFeedback(
        rating: Int,
        functionalityRating: Int,
        easeOfUseRating: Int,
        designRating: Int
    ) async throws {
        let url = baseURL.appendingPathComponent("feedback")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            FeedbackRequest(
                rating: rating,
                functionalityRating: functionalityRating,
                easeOfUseRating: easeOfUseRating,
                designRating: designRating
            )
        )

        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpShouldSetCookies = false
        configuration.httpCookieStorage = nil
        configuration.urlCache = nil
        let session = URLSession(configuration: configuration)

        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    func finishParticipantLogin() {
        isLoggedIn = true
        triggerQueueProcessing(for: number)
        startDeviceHeartbeat()
        Task {
            await flushTelemetryEvents()
            try? await loadMatchMessageOptions()
        }
    }

    func submitInteractions(targetNumber: String, types: [String], message: String = "") async throws -> InteractionSubmissionResult {
        let senderNumber = number.normalizedEventNumber
        let normalizedTargetNumber = targetNumber.normalizedEventNumber
        let supportedTypes = Set(["normal", "hot", "bjob", "hjob", "ljob"])
        guard !senderNumber.isEmpty,
              !normalizedTargetNumber.isEmpty,
              senderNumber != normalizedTargetNumber,
              !types.isEmpty,
              types.allSatisfy(supportedTypes.contains) else {
            throw InteractionSendError.rejected
        }

        let batchID = UUID()
        let now = Date()
        let cleanMessage = String(message.trimmingCharacters(in: .whitespacesAndNewlines).prefix(180))
        let interactions = types.map { type in
            PendingInteraction(
                id: UUID(),
                batchID: batchID,
                senderNumber: senderNumber,
                targetNumber: normalizedTargetNumber,
                type: type,
                kind: type == "normal" || type == "hot" ? .match : .action,
                message: type == "normal" || type == "hot" ? cleanMessage : nil,
                createdAt: now,
                retryCount: 0,
                nextAttemptAt: now
            )
        }

        pendingInteractions.append(contentsOf: interactions)
        persistPendingInteractions()
        updateQueuedSendCount()
        for interaction in interactions {
            recordTelemetry(
                severity: "info",
                category: "queue",
                eventType: "interaction_queued",
                interaction: interaction,
                status: "queued",
                context: [
                    "kind": interaction.kind.rawValue,
                    "interaction_type": interaction.type,
                    "queue_count": String(queuedSendCount),
                ]
            )
        }

        let messages = await processSendQueue(for: senderNumber, collecting: Set(interactions.map(\.id)))
        let queuedCount = pendingInteractions.filter { $0.batchID == batchID }.count
        guard queuedCount > 0 || messages.count == interactions.count else {
            throw InteractionSendError.rejected
        }
        return InteractionSubmissionResult(messages: messages, queuedCount: queuedCount)
    }

    func retryPendingSends() async {
        let senderNumber = number.normalizedEventNumber
        guard !senderNumber.isEmpty else { return }
        for index in pendingInteractions.indices where pendingInteractions[index].senderNumber == senderNumber {
            pendingInteractions[index].nextAttemptAt = Date()
            pendingInteractions[index].retryCount = 0
            persistPendingInteractions()
        }
        _ = await processSendQueue(for: senderNumber)
    }

    func applicationDidBecomeActive() {
        isApplicationActive = true
        startConnectionPolling()
        Task { @MainActor [weak self] in
            await self?.checkConnection()
            guard self?.isApplicationActive == true,
                  self?.connectionState == .online else { return }
            await self?.retryPendingSends()
            self?.startDeviceHeartbeat()
            if self?.isAdmin == true {
                await self?.syncAdminPushToken()
            }
        }
    }

    func applicationDidEnterBackground() {
        isApplicationActive = false
        connectionPollingTask?.cancel()
        connectionPollingTask = nil
        heartbeatTask?.cancel()
        heartbeatTask = nil
    }

    func checkConnection() async {
        guard isApplicationActive else { return }
        guard !isCheckingConnection else { return }
        guard isNetworkAvailable else {
            setConnectionState(.offline)
            return
        }

        isCheckingConnection = true
        defer { isCheckingConnection = false }

        let url = baseURL.appendingPathComponent("status")
        var request = URLRequest(url: url)
        request.timeoutInterval = 6

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {
                setConnectionState(.serverUnavailable)
                return
            }
            if let status = try? JSONDecoder().decode(ParticipantStatusResponse.self, from: data) {
                handleEventBoundary(status.eventID)
                if isLoggedIn, !isAdmin, !status.loggedIn {
                    expireLocalParticipantSession()
                }
            }

            setConnectionState(.online)
            if isLoggedIn, !number.isEmpty {
                triggerQueueProcessing(for: number)
                await flushTelemetryEvents()
            }
        } catch let error as URLError where error.code == .notConnectedToInternet {
            setConnectionState(.offline)
        } catch {
            setConnectionState(.serverUnavailable)
        }
    }

    private func sendMatch(_ interaction: PendingInteraction) async throws -> String {
        let url = baseURL.appendingPathComponent("match")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = formBody([
            "target_number": interaction.targetNumber,
            "match_type": interaction.type,
            "request_id": interaction.id.uuidString.lowercased(),
            "message": interaction.message ?? ""
        ])
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 12

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw InteractionSendError.invalidResponse
        }
        guard http.statusCode == 200 else {
            throw InteractionSendError.httpStatus(http.statusCode)
        }

        let decoded = try JSONDecoder().decode(MatchResponse.self, from: data)
        guard decoded.success else { throw InteractionSendError.rejected }
        return decoded.data
    }

    func loadMatchMessageOptions() async throws {
        let url = baseURL.appendingPathComponent("match-message-options")
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw URLError(.badServerResponse) }
        matchMessageOptions = try JSONDecoder().decode(MatchMessageOptionsResponse.self, from: data).options
    }
    
    @MainActor
    func loadMatches() async throws -> [Match] {
        let url = baseURL.appendingPathComponent("matches")
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode([Match].self, from: data)
        return decoded
    }

    func loadIncomingInterests() async throws -> [IncomingInterest] {
        let url = baseURL.appendingPathComponent("interests")
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode([IncomingInterest].self, from: data)
    }
    
    @MainActor
    func loadActions() async throws -> [SecretAction] {
        let url = baseURL.appendingPathComponent("actions")
        let (data, _) = try await URLSession.shared.data(from: url)
        
        return try JSONDecoder().decode([SecretAction].self, from: data)
    }
    
    @MainActor
    private func sendAction(_ interaction: PendingInteraction) async throws -> String {
        let url = baseURL.appendingPathComponent("actions")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "target_number": interaction.targetNumber,
            "action_type": interaction.type,
            "request_id": interaction.id.uuidString.lowercased()
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 12

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw InteractionSendError.invalidResponse
        }

        if http.statusCode != 200 {
            throw InteractionSendError.httpStatus(http.statusCode)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["message"] as? String ?? "Aktion gespeichert"
    }
    
    @MainActor
    func adminLogin(password: String) async -> Bool {
        let url = baseURL.appendingPathComponent("admin/login")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = formBody(["password": password])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let success = (response as? HTTPURLResponse)?.statusCode == 200

            if success {
                let login = try JSONDecoder().decode(AdminLoginResponse.self, from: data)
                adminToken = login.token
                AdminSessionStore.saveToken(login.token)
                hasSavedAdminSession = true
                isAdmin = true
                isLoggedIn = false
                number = ""
                matches = []
                actions = []
            }

            return success
        } catch {
            return false
        }
    }

    func unlockSavedAdminSession() -> Bool {
        guard let adminToken, !adminToken.isEmpty else {
            hasSavedAdminSession = false
            return false
        }

        isAdmin = true
        isLoggedIn = false
        number = ""
        matches = []
        actions = []
        return true
    }

    func registerAdminPushToken(_ token: String, environment: String) async {
        guard token.count >= 32, token.count <= 200, token.count.isMultiple(of: 2),
              token.range(of: "^[0-9a-f]+$", options: .regularExpression) != nil,
              environment == "sandbox" || environment == "production" else { return }
        UserDefaults.standard.set(token, forKey: Self.adminPushTokenKey)
        UserDefaults.standard.set(environment, forKey: Self.adminPushEnvironmentKey)
        await syncAdminPushToken()
    }

    private func syncAdminPushToken() async {
        guard adminToken != nil,
              let token = UserDefaults.standard.string(forKey: Self.adminPushTokenKey),
              let environment = UserDefaults.standard.string(forKey: Self.adminPushEnvironmentKey) else { return }
        do {
            let url = baseURL.appendingPathComponent("admin/push-token")
            var request = try adminRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "device_token": token,
                "environment": environment,
            ])
            let (_, response) = try await URLSession.shared.data(for: request)
            try validateAdminResponse(response)
        } catch {
            // A later activation or APNs registration retries without logging token details.
        }
    }

    func unregisterAdminPushToken() async {
        guard adminToken != nil,
              let token = UserDefaults.standard.string(forKey: Self.adminPushTokenKey) else { return }
        do {
            let url = baseURL.appendingPathComponent("admin/push-token")
            var request = try adminRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: ["device_token": token])
            let (_, response) = try await URLSession.shared.data(for: request)
            try validateAdminResponse(response)
        } catch {
            // Explicit logout also attempts removal; network failures remain non-blocking.
        }
    }
    
    @MainActor
    func loadAdminActions() async throws {
        let url = baseURL.appendingPathComponent("admin/actions")

        let (data, response) = try await URLSession.shared.data(for: adminRequest(url: url))
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            handleExpiredAdminToken(response)
            throw URLError(.badServerResponse)
        }

        adminActions = try JSONDecoder().decode([AdminAction].self, from: data)
    }
    
    @MainActor
    func loadAdminMatches() async throws {
        let url = baseURL.appendingPathComponent("admin/matches")

        let (data, response) = try await URLSession.shared.data(for: adminRequest(url: url))
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            handleExpiredAdminToken(response)
            throw URLError(.badServerResponse)
        }

        adminMatches = try JSONDecoder().decode([AdminMatch].self, from: data)
    }

    @MainActor
    func loadAdminMatchRequests() async throws {
        let url = baseURL.appendingPathComponent("admin/requests")

        let (data, response) = try await URLSession.shared.data(for: adminRequest(url: url))
        try validateAdminResponse(response)
        adminMatchRequests = try JSONDecoder().decode([AdminMatchRequest].self, from: data)
    }

    func loadAdminFeedback() async throws {
        let url = baseURL.appendingPathComponent("admin/feedback")
        let request = try adminRequest(url: url)
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError where error.code == .cancelled && !Task.isCancelled {
            (data, response) = try await URLSession.shared.data(for: request)
        }
        guard let http = response as? HTTPURLResponse else {
            throw AdminFeedbackLoadError.invalidResponse
        }
        if http.statusCode == 401 || http.statusCode == 403 {
            handleExpiredAdminToken(response)
            throw AdminFeedbackLoadError.sessionExpired
        }
        guard http.statusCode == 200 else {
            throw AdminFeedbackLoadError.server(statusCode: http.statusCode)
        }

        let decoder = JSONDecoder()
        do {
            let feedback = try decoder.decode([AdminFeedback]?.self, from: data)
            adminFeedback = feedback ?? []
            return
        } catch {
            // Older module versions may wrap the list in an object.
        }
        if let envelope = try? decoder.decode(AdminFeedbackEnvelope.self, from: data),
           let feedback = envelope.feedback ?? envelope.data {
            adminFeedback = feedback
            return
        }

        throw AdminFeedbackLoadError.invalidPayload
    }

    func createBillboardAccessURL(name: String? = nil) async throws -> URL {
        let url = baseURL.appendingPathComponent("admin/billboard-access")
        var request = try adminRequest(url: url)
        request.httpMethod = "POST"
        if let name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            request.httpBody = try JSONSerialization.data(withJSONObject: ["name": name])
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            handleExpiredAdminToken(response)
            throw URLError(.userAuthenticationRequired)
        }

        let access = try JSONDecoder().decode(BillboardAccessResponse.self, from: data)
        guard let accessURL = URL(string: access.url) else {
            throw URLError(.badURL)
        }
        return accessURL
    }

    func updateAdminDeviceName(id: String, name: String) async throws {
        try await mutateAdminResource(
            path: ["admin", "devices", id],
            method: "PATCH",
            body: ["name": name]
        )
        try? await loadAdminDashboard()
    }

    func updateAdminBillboardName(id: String, name: String) async throws {
        try await mutateAdminResource(
            path: ["admin", "billboards", id],
            method: "PATCH",
            body: ["name": name]
        )
        try? await loadAdminDashboard()
    }

    func loadAdminDashboard() async throws {
        let url = baseURL.appendingPathComponent("admin/dashboard")
        let (data, response) = try await URLSession.shared.data(for: adminRequest(url: url))
        try validateAdminResponse(response)
        adminDashboard = try JSONDecoder().decode(AdminDashboard.self, from: data)
    }

    func loadAdminEventLog(
        severity: String? = nil,
        category: String? = nil,
        search: String = "",
        beforeID: String? = nil
    ) async throws -> Int {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("admin/event-log"),
            resolvingAgainstBaseURL: false
        )
        var items = [URLQueryItem(name: "limit", value: "100")]
        if let severity, !severity.isEmpty { items.append(URLQueryItem(name: "severity", value: severity)) }
        if let category, !category.isEmpty { items.append(URLQueryItem(name: "category", value: category)) }
        if !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            items.append(URLQueryItem(name: "search", value: search.trimmingCharacters(in: .whitespacesAndNewlines)))
        }
        if let beforeID, !beforeID.isEmpty { items.append(URLQueryItem(name: "before_id", value: beforeID)) }
        components?.queryItems = items
        guard let url = components?.url else { throw URLError(.badURL) }

        let (data, response) = try await URLSession.shared.data(for: adminRequest(url: url))
        try validateAdminResponse(response)
        let entries = try JSONDecoder().decode([AdminEventLogEntry].self, from: data)
        if beforeID == nil {
            adminEventLog = entries
        } else {
            let existing = Set(adminEventLog.map(\.id))
            adminEventLog.append(contentsOf: entries.filter { !existing.contains($0.id) })
        }
        return entries.count
    }

    func loadAdminStatistics() async throws {
        let url = baseURL.appendingPathComponent("admin/statistics")
        let (data, response) = try await URLSession.shared.data(for: adminRequest(url: url))
        try validateAdminResponse(response)
        adminStatistics = try JSONDecoder().decode(AdminStatisticsResponse.self, from: data)
    }

    func loadAdminParticipants() async throws {
        let url = baseURL.appendingPathComponent("admin/participants")
        let (data, response) = try await URLSession.shared.data(for: adminRequest(url: url))
        try validateAdminResponse(response)
        adminParticipants = try JSONDecoder().decode(AdminParticipants.self, from: data)
    }

    func createAdminAction(senderNumber: String, receiverNumber: String, type: String) async throws {
        try await mutateAdminResource(
            path: ["admin", "actions"],
            method: "POST",
            body: [
                "sender_number": senderNumber.normalizedEventNumber,
                "receiver_number": receiverNumber.normalizedEventNumber,
                "action_type": type
            ]
        )
        try? await loadAdminActions()
        try? await loadAdminDashboard()
    }

    func updateAdminAction(id: String, senderNumber: String, receiverNumber: String, type: String) async throws {
        try await mutateAdminResource(
            path: ["admin", "actions", id],
            method: "PATCH",
            body: [
                "sender_number": senderNumber.normalizedEventNumber,
                "receiver_number": receiverNumber.normalizedEventNumber,
                "action_type": type
            ]
        )
        try? await loadAdminActions()
    }

    func createAdminMatch(numberA: String, numberB: String, type: String) async throws {
        try await mutateAdminResource(
            path: ["admin", "matches"],
            method: "POST",
            body: [
                "number_a": numberA.normalizedEventNumber,
                "number_b": numberB.normalizedEventNumber,
                "type": type
            ]
        )
        try? await loadAdminMatches()
        try? await loadAdminDashboard()
    }

    func updateAdminMatch(id: String, numberA: String, numberB: String, type: String) async throws {
        try await mutateAdminResource(
            path: ["admin", "matches", id],
            method: "PATCH",
            body: [
                "number_a": numberA.normalizedEventNumber,
                "number_b": numberB.normalizedEventNumber,
                "type": type
            ]
        )
        try? await loadAdminMatches()
    }

    func updateAdminMatchRequest(
        id: String,
        participantA: String,
        participantB: String,
        type: String,
        message: String
    ) async throws {
        try await mutateAdminResource(
            path: ["admin", "requests", id],
            method: "PATCH",
            body: [
                "participant_a": participantA.normalizedEventNumber,
                "participant_b": participantB.normalizedEventNumber,
                "type": type,
                "message": message
            ]
        )
        try? await loadAdminMatchRequests()
        try? await loadAdminDashboard()
    }

    func createAdminParticipant(number: String) async throws {
        try await mutateAdminResource(
            path: ["admin", "participants"],
            method: "POST",
            body: ["number": number.normalizedEventNumber]
        )
        try? await loadAdminParticipants()
        try? await loadAdminDashboard()
    }

    func reconcileParticipantRange(targetMax: Int, confirmation: String) async throws -> ParticipantRangeResponse {
        let url = baseURL
            .appendingPathComponent("admin")
            .appendingPathComponent("participants")
            .appendingPathComponent("range")
        var request = try adminRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "target_max": targetMax,
            "confirmation": confirmation
        ])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            handleExpiredAdminToken(response)
            let responseError = try? JSONDecoder().decode(AdminMutationResponseError.self, from: data)
            throw AdminMutationError(message: responseError?.message ?? "Nummernbereich konnte nicht geändert werden.")
        }
        let result = try JSONDecoder().decode(ParticipantRangeResponse.self, from: data)
        try? await loadAdminParticipants()
        try? await loadAdminDashboard()
        return result
    }

    func updateParticipantGender(number: String, gender: ParticipantGender?) async throws {
        try await mutateAdminResource(
            path: ["admin", "participants", number.normalizedEventNumber],
            method: "PATCH",
            body: ["gender": gender?.rawValue ?? NSNull()]
        )
        try? await loadAdminParticipants()
        try? await loadAdminDashboard()
    }

    func updateParticipantPIN(number: String, pin: String) async throws {
        try await mutateAdminResource(
            path: ["admin", "participants", number.normalizedEventNumber],
            method: "PATCH",
            body: ["pin": pin]
        )
        try? await loadAdminParticipants()
    }

    func resetParticipantPIN(number: String) async throws {
        let url = baseURL
            .appendingPathComponent("admin")
            .appendingPathComponent("participants")
            .appendingPathComponent(number.normalizedEventNumber)
        var request = try adminRequest(url: url)
        request.httpMethod = "PATCH"
        request.httpBody = try JSONSerialization.data(withJSONObject: ["reset_pin": true])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            handleExpiredAdminToken(response)
            let responseError = try? JSONDecoder().decode(AdminMutationResponseError.self, from: data)
            throw AdminMutationError(message: responseError?.message ?? "PIN-Reset fehlgeschlagen.")
        }
        let result = try JSONDecoder().decode(AdminParticipantMutationResponse.self, from: data)
        try? await loadAdminParticipants()
        guard result.pinReset else { throw AdminMutationError(message: "PIN-Reset wurde nicht bestätigt.") }
    }

    func updateMatchMessageOptions(_ options: [String]) async throws {
        try await mutateAdminResource(
            path: ["admin", "match-message-options"],
            method: "PATCH",
            body: ["options": options]
        )
        try? await loadAdminDashboard()
    }

    func controlBillboard(action: String, seconds: Int? = nil) async throws {
        let url = baseURL.appendingPathComponent("admin/billboard-control")
        var request = try adminRequest(url: url)
        request.httpMethod = "POST"
        var body: [String: Any] = ["action": action]
        if let seconds {
            body["seconds"] = seconds
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (_, response) = try await URLSession.shared.data(for: request)
        try validateAdminResponse(response)
        try await loadAdminDashboard()
    }

    func manageDummyData(action: String) async throws {
        let url = baseURL.appendingPathComponent("admin/dummy-data")
        var request = try adminRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: ["action": action])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (_, response) = try await URLSession.shared.data(for: request)
        try validateAdminResponse(response)
        try await refreshAdminControlData()
    }

    func deleteAdminAction(id: String) async throws {
        let url = baseURL
            .appendingPathComponent("admin/actions")
            .appendingPathComponent(id)
        var request = try adminRequest(url: url)
        request.httpMethod = "DELETE"
        let (_, response) = try await URLSession.shared.data(for: request)
        try validateAdminResponse(response)
        adminActions.removeAll { $0.id == id }
        try? await loadAdminDashboard()
    }

    func deleteAdminMatch(id: String) async throws {
        let url = baseURL
            .appendingPathComponent("admin/matches")
            .appendingPathComponent(id)
        var request = try adminRequest(url: url)
        request.httpMethod = "DELETE"
        let (_, response) = try await URLSession.shared.data(for: request)
        try validateAdminResponse(response)
        adminMatches.removeAll { $0.id == id }
        try? await loadAdminDashboard()
    }

    func deleteAdminMatchRequest(id: String) async throws {
        let url = baseURL
            .appendingPathComponent("admin/requests")
            .appendingPathComponent(id)
        var request = try adminRequest(url: url)
        request.httpMethod = "DELETE"
        let (_, response) = try await URLSession.shared.data(for: request)
        try validateAdminResponse(response)
        adminMatchRequests.removeAll { $0.id == id }
        try? await loadAdminDashboard()
    }

    func deleteAdminFeedback(id: String) async throws {
        let url = baseURL
            .appendingPathComponent("admin/feedback")
            .appendingPathComponent(id)
        var request = try adminRequest(url: url)
        request.httpMethod = "DELETE"
        let (_, response) = try await URLSession.shared.data(for: request)
        try validateAdminResponse(response)
        adminFeedback.removeAll { $0.id == id }
    }

    func logoutParticipant(number: String) async throws {
        try await participantCommand(number: number, suffix: "logout", method: "POST")
    }

    func blockParticipant(number: String) async throws {
        try await participantCommand(number: number, suffix: nil, method: "DELETE")
    }

    func resetEvent(confirmation: String) async throws -> EventResetResponse {
        let url = baseURL.appendingPathComponent("admin/event-reset")
        var request = try adminRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: ["confirmation": confirmation])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateAdminResponse(response)
        let result = try JSONDecoder().decode(EventResetResponse.self, from: data)
        adminActions = []
        adminMatches = []
        adminMatchRequests = []
        adminFeedback = []
        adminEventLog = []
        try await refreshAdminControlData()
        try? await loadAdminStatistics()
        return result
    }

    func refreshAdminControlData() async throws {
        try await loadAdminDashboard()
        try await loadAdminParticipants()
    }

    func logout() {
        if let adminToken {
            let authorization = "Bearer \(adminToken)"
            var logoutRequest = URLRequest(url: baseURL.appendingPathComponent("admin/logout"))
            logoutRequest.httpMethod = "POST"
            logoutRequest.setValue(authorization, forHTTPHeaderField: "Authorization")

            var unregisterRequest: URLRequest?
            if let pushToken = UserDefaults.standard.string(forKey: Self.adminPushTokenKey) {
                var request = URLRequest(url: baseURL.appendingPathComponent("admin/push-token"))
                request.httpMethod = "DELETE"
                request.setValue(authorization, forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try? JSONSerialization.data(withJSONObject: ["device_token": pushToken])
                unregisterRequest = request
            }
            Task {
                if let unregisterRequest {
                    _ = try? await URLSession.shared.data(for: unregisterRequest)
                }
                _ = try? await URLSession.shared.data(for: logoutRequest)
            }
        }

        adminToken = nil
        AdminSessionStore.clearToken()
        hasSavedAdminSession = false
        self.isLoggedIn = false
        self.number = ""
        adminEventLog = []
        adminStatistics = nil
        retryTask?.cancel()
        heartbeatTask?.cancel()
        heartbeatTask = nil
        updateQueuedSendCount()
        self.matches = []
        self.actions = []
        self.adminActions = []
        self.adminMatches = []
        self.adminMatchRequests = []
        self.adminFeedback = []
        self.isAdmin = false
    }

    func cancelParticipantLogin() async {
        if !isAdmin, !number.isEmpty {
            var request = URLRequest(url: baseURL.appendingPathComponent("logout"))
            request.httpMethod = "POST"
            request.timeoutInterval = 3
            _ = try? await URLSession.shared.data(for: request)
        }
        logout()
    }

    private func adminRequest(url: URL) throws -> URLRequest {
        guard let adminToken else {
            throw URLError(.userAuthenticationRequired)
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(adminToken)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func participantCommand(number: String, suffix: String?, method: String) async throws {
        var url = baseURL
            .appendingPathComponent("admin/participants")
            .appendingPathComponent(number)
        if let suffix {
            url.appendPathComponent(suffix)
        }
        var request = try adminRequest(url: url)
        request.httpMethod = method
        let (_, response) = try await URLSession.shared.data(for: request)
        try validateAdminResponse(response)
        try? await loadAdminParticipants()
        try? await loadAdminDashboard()
    }

    private func mutateAdminResource(path: [String], method: String, body: [String: Any]) async throws {
        let url = path.reduce(baseURL) { partialURL, component in
            partialURL.appendingPathComponent(component)
        }
        var request = try adminRequest(url: url)
        request.httpMethod = method
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AdminMutationError(message: "Ungültige Serverantwort.")
        }
        guard (200...299).contains(http.statusCode) else {
            handleExpiredAdminToken(response)
            let responseError = try? JSONDecoder().decode(AdminMutationResponseError.self, from: data)
            throw AdminMutationError(message: responseError?.message ?? "Serverfehler (HTTP \(http.statusCode)).")
        }
    }

    private func validateAdminResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            handleExpiredAdminToken(response)
            throw URLError(.badServerResponse)
        }
    }

    private func formBody(_ values: [String: String]) -> Data? {
        var components = URLComponents()
        components.queryItems = values.map {
            URLQueryItem(name: $0.key, value: $0.value)
        }
        return components.percentEncodedQuery?.data(using: .utf8)
    }

    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                isNetworkAvailable = path.status == .satisfied
                if !isNetworkAvailable {
                    setConnectionState(.offline)
                } else if isApplicationActive {
                    await checkConnection()
                }
            }
        }
        networkMonitor.start(queue: networkMonitorQueue)
    }

    private func setConnectionState(_ newState: ConnectionState) {
        let previous = connectionState
        guard previous != newState else { return }
        connectionState = newState
        guard isLoggedIn else { return }

        let value = telemetryValue(for: newState)
        recordTelemetry(
            severity: newState == .online ? "info" : "warning",
            category: "connectivity",
            eventType: newState == .online ? "connection_recovered" : "connection_lost",
            status: value,
            context: [
                "connection_state": value,
                "result": "from_\(telemetryValue(for: previous))",
            ]
        )
    }

    private func startConnectionPolling() {
        connectionPollingTask?.cancel()
        connectionPollingTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(15))
                } catch {
                    return
                }
                guard !Task.isCancelled else { return }
                await self?.checkConnection()
            }
        }
    }

    private func startDeviceHeartbeat() {
        heartbeatTask?.cancel()
        guard isLoggedIn, isApplicationActive else { return }
        UIDevice.current.isBatteryMonitoringEnabled = true
        heartbeatTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                await self?.sendDeviceHeartbeat()
                do { try await Task.sleep(for: .seconds(30)) } catch { return }
            }
        }
    }

    private func sendDeviceHeartbeat() async {
        guard isLoggedIn else { return }
        let deviceID = installationID
        let rawLevel = UIDevice.current.batteryLevel
        let level = rawLevel < 0 ? 0 : Int((rawLevel * 100).rounded())
        let state: String
        switch UIDevice.current.batteryState {
        case .charging: state = "charging"
        case .full: state = "full"
        case .unplugged: state = "unplugged"
        default: state = "unknown"
        }
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let ownPending = pendingInteractions.filter { $0.senderNumber == number.normalizedEventNumber }
        let oldestPendingSeconds = ownPending.map {
            max(0, Int(Date().timeIntervalSince($0.createdAt)))
        }.max() ?? 0
        let lastSync = UserDefaults.standard.object(forKey: Self.lastSuccessfulSyncKey) as? Date
        var request = URLRequest(url: baseURL.appendingPathComponent("heartbeat"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "device_id": deviceID,
            "battery_level": level,
            "battery_state": state,
            "app_version": version,
            "queued_send_count": ownPending.count,
            "oldest_pending_seconds": oldestPendingSeconds,
            "last_successful_sync_at": lastSync.map(Self.iso8601String) ?? "",
            "connection_state": telemetryValue(for: connectionState),
        ])
        request.timeoutInterval = 8
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return }
            markSuccessfulSync()
            await flushTelemetryEvents()
        } catch {
            return
        }
    }

    private func triggerQueueProcessing(for senderNumber: String) {
        guard !senderNumber.isEmpty else { return }
        Task { @MainActor [weak self] in
            _ = await self?.processSendQueue(for: senderNumber)
        }
    }

    private func processSendQueue(
        for senderNumber: String,
        collecting requestedIDs: Set<UUID> = [],
        allowsLoggedOutSession: Bool = false
    ) async -> [String] {
        removeExpiredPendingInteractions()
        guard !isProcessingSendQueue, isNetworkAvailable else {
            scheduleRetry(for: senderNumber)
            return []
        }

        isProcessingSendQueue = true
        isRetryingQueuedSends = true
        retryTask?.cancel()
        defer {
            isProcessingSendQueue = false
            isRetryingQueuedSends = false
            updateQueuedSendCount()
            scheduleRetry(for: senderNumber)
        }

        var messages: [String] = []

        while (allowsLoggedOutSession || (isLoggedIn && number.normalizedEventNumber == senderNumber)),
              let index = nextPendingInteractionIndex(for: senderNumber) {
            let interaction = pendingInteractions[index]
            recordTelemetry(
                severity: "info",
                category: "queue",
                eventType: "interaction_send_started",
                interaction: interaction,
                status: "sending",
                context: [
                    "kind": interaction.kind.rawValue,
                    "interaction_type": interaction.type,
                    "retry_count": String(interaction.retryCount),
                ]
            )
            do {
                let message: String
                switch interaction.kind {
                case .match:
                    message = try await sendMatch(interaction)
                case .action:
                    message = try await sendAction(interaction)
                }

                pendingInteractions.remove(at: index)
                persistPendingInteractions()
                markSuccessfulSync()
                recordTelemetry(
                    severity: "info",
                    category: "queue",
                    eventType: "interaction_delivered",
                    interaction: interaction,
                    status: "delivered",
                    context: [
                        "kind": interaction.kind.rawValue,
                        "interaction_type": interaction.type,
                        "retry_count": String(interaction.retryCount),
                    ]
                )
                if requestedIDs.contains(interaction.id) {
                    messages.append(message)
                }
            } catch {
                if shouldRetry(error) {
                    markPendingInteractionForRetry(at: index)
                    let retryCount = pendingInteractions[index].retryCount
                    recordTelemetry(
                        severity: "warning",
                        category: "queue",
                        eventType: "interaction_retry_scheduled",
                        interaction: interaction,
                        status: "retrying",
                        context: [
                            "kind": interaction.kind.rawValue,
                            "interaction_type": interaction.type,
                            "retry_count": String(retryCount),
                            "error_code": telemetryErrorCode(error),
                            "queue_count": String(pendingInteractions.filter { $0.senderNumber == senderNumber }.count),
                        ]
                    )
                    break
                }

                pendingInteractions.remove(at: index)
                persistPendingInteractions()
                recordTelemetry(
                    severity: "error",
                    category: "queue",
                    eventType: "interaction_rejected",
                    interaction: interaction,
                    status: "rejected",
                    context: [
                        "kind": interaction.kind.rawValue,
                        "interaction_type": interaction.type,
                        "retry_count": String(interaction.retryCount),
                        "error_code": telemetryErrorCode(error),
                    ]
                )
                throwAwayInvalidBatchIfNeeded(batchID: interaction.batchID, senderNumber: senderNumber)
            }
        }

        await flushTelemetryEvents()
        return messages
    }

    private func nextPendingInteractionIndex(for senderNumber: String) -> Int? {
        let now = Date()
        guard let index = pendingInteractions.firstIndex(where: { $0.senderNumber == senderNumber }),
              pendingInteractions[index].nextAttemptAt <= now else {
            return nil
        }
        return index
    }

    private func markPendingInteractionForRetry(at index: Int) {
        pendingInteractions[index].retryCount += 1
        let exponent = min(pendingInteractions[index].retryCount - 1, 4)
        let delay = min(pow(2, Double(exponent)) * 2, 30)
        pendingInteractions[index].nextAttemptAt = Date().addingTimeInterval(delay)
        persistPendingInteractions()
    }

    private func throwAwayInvalidBatchIfNeeded(batchID: UUID, senderNumber: String) {
        pendingInteractions.removeAll {
            $0.batchID == batchID && $0.senderNumber == senderNumber
        }
        persistPendingInteractions()
    }

    private func shouldRetry(_ error: Error) -> Bool {
        if let sendError = error as? InteractionSendError {
            switch sendError {
            case .invalidResponse:
                return true
            case .httpStatus(let statusCode):
                return statusCode == 401
                    || statusCode == 403
                    || statusCode == 408
                    || statusCode == 425
                    || statusCode == 429
                    || statusCode >= 500
            case .rejected:
                return false
            }
        }

        guard let urlError = error as? URLError else {
            return error is DecodingError
        }

        return [
            .cannotFindHost,
            .cannotConnectToHost,
            .dataNotAllowed,
            .dnsLookupFailed,
            .internationalRoamingOff,
            .networkConnectionLost,
            .notConnectedToInternet,
            .resourceUnavailable,
            .secureConnectionFailed,
            .timedOut
        ].contains(urlError.code)
    }

    private func scheduleRetry(for senderNumber: String) {
        retryTask?.cancel()
        guard isNetworkAvailable,
              isLoggedIn,
              number.normalizedEventNumber == senderNumber,
              let nextAttempt = pendingInteractions
                .first(where: { $0.senderNumber == senderNumber })?
                .nextAttemptAt else {
            return
        }

        let delay = max(0.25, nextAttempt.timeIntervalSinceNow)
        retryTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: .seconds(delay))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            self?.retryTask = nil
            _ = await self?.processSendQueue(for: senderNumber)
        }
    }

    private func retryPendingSendsForPreviousSession() async {
        guard isNetworkAvailable,
              !pendingInteractions.isEmpty,
              number.isEmpty,
              let sessionNumber = try? await loadServerSessionNumber(),
              !sessionNumber.isEmpty else {
            return
        }

        _ = await processSendQueue(for: sessionNumber, allowsLoggedOutSession: true)
    }

    private func waitForSendQueueToFinish() async {
        while isProcessingSendQueue {
            do {
                try await Task.sleep(for: .milliseconds(50))
            } catch {
                return
            }
        }
    }

    private func loadServerSessionNumber() async throws -> String {
        let url = baseURL.appendingPathComponent("status")
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw InteractionSendError.invalidResponse
        }
        let status = try JSONDecoder().decode(ParticipantStatusResponse.self, from: data)
        handleEventBoundary(status.eventID)
        return status.loggedIn ? status.number?.normalizedEventNumber ?? "" : ""
    }

    private func updateQueuedSendCount() {
        let senderNumber = number.normalizedEventNumber
        queuedSendCount = pendingInteractions.filter { $0.senderNumber == senderNumber }.count
    }

    private func persistPendingInteractions() {
        guard let data = try? JSONEncoder().encode(pendingInteractions) else { return }
        UserDefaults.standard.set(data, forKey: Self.pendingInteractionsKey)
        updateQueuedSendCount()
    }

    private static func loadPendingInteractions() -> [PendingInteraction] {
        guard let data = UserDefaults.standard.data(forKey: pendingInteractionsKey),
              let interactions = try? JSONDecoder().decode([PendingInteraction].self, from: data) else {
            return []
        }
        return interactions
    }

    private func removeExpiredPendingInteractions() {
        let cutoff = Date().addingTimeInterval(-Self.pendingInteractionLifetime)
        let originalCount = pendingInteractions.count
        pendingInteractions.removeAll { $0.createdAt < cutoff }
        if pendingInteractions.count != originalCount {
            persistPendingInteractions()
        } else {
            updateQueuedSendCount()
        }
    }

    private var installationID: String {
        let defaults = UserDefaults.standard
        if let saved = defaults.string(forKey: Self.installationIDKey), !saved.isEmpty {
            return saved
        }
        let created = UUID().uuidString.lowercased()
        defaults.set(created, forKey: Self.installationIDKey)
        return created
    }

    private func recordTelemetry(
        severity: String,
        category: String,
        eventType: String,
        interaction: PendingInteraction? = nil,
        status: String? = nil,
        context: [String: String] = [:]
    ) {
        let event = PendingTelemetryEvent(
            id: UUID(),
            occurredAt: Self.iso8601String(Date()),
            severity: severity,
            category: category,
            eventType: eventType,
            deviceID: installationID,
            targetNumber: interaction?.targetNumber,
            requestID: interaction?.id.uuidString.lowercased(),
            status: status,
            context: context
        )
        pendingTelemetryEvents.append(event)
        removeExpiredTelemetryEvents()
        if pendingTelemetryEvents.count > 500 {
            pendingTelemetryEvents.removeFirst(pendingTelemetryEvents.count - 500)
        }
        persistPendingTelemetryEvents()
    }

    private func flushTelemetryEvents(allowsLoggedOutSession: Bool = false) async {
        guard !isFlushingTelemetry,
              isNetworkAvailable,
              isLoggedIn || allowsLoggedOutSession,
              !pendingTelemetryEvents.isEmpty else { return }

        isFlushingTelemetry = true
        defer { isFlushingTelemetry = false }

        while !pendingTelemetryEvents.isEmpty {
            let batch = Array(pendingTelemetryEvents.prefix(50))
            var request = URLRequest(url: baseURL.appendingPathComponent("telemetry/events"))
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 10
            request.httpBody = try? JSONEncoder().encode(TelemetryEnvelope(events: batch))

            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    return
                }
                let sentIDs = Set(batch.map(\.id))
                pendingTelemetryEvents.removeAll { sentIDs.contains($0.id) }
                persistPendingTelemetryEvents()
            } catch {
                return
            }
        }
    }

    private func persistPendingTelemetryEvents() {
        guard let data = try? JSONEncoder().encode(pendingTelemetryEvents) else { return }
        UserDefaults.standard.set(data, forKey: Self.pendingTelemetryKey)
    }

    private static func loadPendingTelemetryEvents() -> [PendingTelemetryEvent] {
        guard let data = UserDefaults.standard.data(forKey: pendingTelemetryKey),
              let events = try? JSONDecoder().decode([PendingTelemetryEvent].self, from: data) else {
            return []
        }
        return events
    }

    private func removeExpiredTelemetryEvents() {
        let cutoff = Date().addingTimeInterval(-Self.telemetryLifetime)
        pendingTelemetryEvents.removeAll {
            guard let date = ISO8601DateFormatter().date(from: $0.occurredAt) else { return true }
            return date < cutoff
        }
    }

    private func markSuccessfulSync() {
        UserDefaults.standard.set(Date(), forKey: Self.lastSuccessfulSyncKey)
    }

    private func handleEventBoundary(_ serverEventID: String?) {
        guard let serverEventID, !serverEventID.isEmpty else { return }
        let defaults = UserDefaults.standard
        guard let previous = defaults.string(forKey: Self.eventIDKey), !previous.isEmpty else {
            defaults.set(serverEventID, forKey: Self.eventIDKey)
            return
        }
        guard previous != serverEventID else { return }

        pendingInteractions.removeAll()
        pendingTelemetryEvents.removeAll()
        persistPendingInteractions()
        persistPendingTelemetryEvents()
        defaults.removeObject(forKey: Self.lastSuccessfulSyncKey)
        defaults.set(serverEventID, forKey: Self.eventIDKey)
    }

    private func expireLocalParticipantSession() {
        guard !isAdmin else { return }
        isLoggedIn = false
        number = ""
        heartbeatTask?.cancel()
        heartbeatTask = nil
        retryTask?.cancel()
        matches = []
        actions = []
        updateQueuedSendCount()
    }

    private func telemetryValue(for state: ConnectionState) -> String {
        switch state {
        case .checking: return "checking"
        case .online: return "online"
        case .offline: return "offline"
        case .serverUnavailable: return "server_unavailable"
        }
    }

    private func telemetryErrorCode(_ error: Error) -> String {
        if let sendError = error as? InteractionSendError {
            switch sendError {
            case .invalidResponse: return "invalid_response"
            case .httpStatus(let status): return "http_\(status)"
            case .rejected: return "rejected"
            }
        }
        if let urlError = error as? URLError {
            return "url_\(urlError.code.rawValue)"
        }
        if error is DecodingError {
            return "decoding"
        }
        return "unknown"
    }

    private static func iso8601String(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private func handleExpiredAdminToken(_ response: URLResponse) {
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode,
              statusCode == 401 || statusCode == 403 else {
            return
        }

        adminToken = nil
        AdminSessionStore.clearToken()
        hasSavedAdminSession = false
        isAdmin = false
    }
}

private struct TelemetryEnvelope: Encodable {
    let events: [PendingTelemetryEvent]
}

private enum InteractionSendError: Error {
    case invalidResponse
    case httpStatus(Int)
    case rejected
}

private struct AdminMutationResponseError: Decodable {
    let message: String
}

private struct AdminParticipantMutationResponse: Decodable {
    let pin: String?
    let pinReset: Bool

    private enum CodingKeys: String, CodingKey {
        case pin
        case pinReset = "pin_reset"
    }
}

private struct AdminMutationError: LocalizedError {
    let message: String

    var errorDescription: String? { message }
}

private struct ParticipantStatusResponse: Decodable {
    let loggedIn: Bool
    let number: String?
    let eventID: String?

    private enum CodingKeys: String, CodingKey {
        case loggedIn = "logged_in"
        case number
        case eventID = "event_id"
    }
}

private struct MatchMessageOptionsResponse: Decodable {
    let options: [String]
}

private struct AdminLoginResponse: Decodable {
    let token: String
}

private struct AdminFeedbackEnvelope: Decodable {
    let feedback: [AdminFeedback]?
    let data: [AdminFeedback]?
}

enum AdminFeedbackLoadError: LocalizedError {
    case invalidResponse
    case sessionExpired
    case server(statusCode: Int)
    case invalidPayload

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Der Feedback-Server hat nicht korrekt geantwortet."
        case .sessionExpired:
            return "Die Admin-Sitzung ist abgelaufen. Bitte erneut anmelden."
        case .server(let statusCode):
            return "Feedback konnte wegen eines Serverfehlers nicht geladen werden (HTTP \(statusCode))."
        case .invalidPayload:
            return "Die Feedback-Antwort hat ein unbekanntes Format."
        }
    }
}

private struct FeedbackRequest: Encodable {
    let rating: Int
    let functionalityRating: Int
    let easeOfUseRating: Int
    let designRating: Int

    private enum CodingKeys: String, CodingKey {
        case rating
        case functionalityRating = "functionality_rating"
        case easeOfUseRating = "ease_of_use_rating"
        case designRating = "design_rating"
    }
}

private struct BillboardAccessResponse: Decodable {
    let url: String
    let expiresIn: Int

    private enum CodingKeys: String, CodingKey {
        case url
        case expiresIn = "expires_in"
    }
}

extension String {
    var normalizedEventNumber: String {
        let digits = trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        let normalized = digits.drop(while: { $0 == "0" })
        return normalized.isEmpty && !digits.isEmpty ? "0" : String(normalized)
    }

    var displayEventNumber: String {
        let cleaned = trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        guard !cleaned.isEmpty,
              cleaned.allSatisfy(\.isNumber),
              cleaned.count < 3 else {
            return cleaned
        }
        return String(repeating: "0", count: 3 - cleaned.count) + cleaned
    }
}
