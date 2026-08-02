import Foundation
import Combine
import SwiftUI

@MainActor
class APIService: ObservableObject {
    static let shared = APIService()
    private init() {
        if let savedAdminToken = AdminSessionStore.loadToken(), !savedAdminToken.isEmpty {
            adminToken = savedAdminToken
            hasSavedAdminSession = true
        }
    }

    @Published var isLoggedIn: Bool = false
    @Published var number: String = ""
    @Published var matches: [Match] = []
    @Published var actions: [SecretAction] = []
    @Published var isAdmin: Bool = false
    @Published private(set) var hasSavedAdminSession: Bool = false
    @Published var adminActions: [AdminAction] = []
    @Published var adminMatches: [AdminMatch] = []
    @Published var adminDashboard: AdminDashboard?
    @Published var adminParticipants = AdminParticipants(allowed: [], active: [])
    private var adminToken: String?
    private let baseURL = URL(string: "https://secret-match.de/wp-json/secretmatch/v1")!

    func login(number: String) async throws {
        if isAdmin { return }
        let normalizedNumber = number.normalizedEventNumber
        let url = baseURL.appendingPathComponent("login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = formBody(["secretmatch_number": normalizedNumber])
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        self.isLoggedIn = true
        self.number = normalizedNumber
    }

    func submitMatch(targetNumber: String, type: String) async throws -> String {
        let normalizedTargetNumber = targetNumber.normalizedEventNumber
        let url = baseURL.appendingPathComponent("match")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = formBody([
            "target_number": normalizedTargetNumber,
            "match_type": type
        ])
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(MatchResponse.self, from: data)
        return decoded.data
    }
    
    @MainActor
    func loadMatches() async throws -> [Match] {
        let url = baseURL.appendingPathComponent("matches")
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        print(String(data: data, encoding: .utf8) ?? "Kein JSON")

        let decoded = try JSONDecoder().decode([Match].self, from: data)
        return decoded
    }
    
    @MainActor
    func loadActions() async throws -> [SecretAction] {
        let url = baseURL.appendingPathComponent("actions")
        let (data, _) = try await URLSession.shared.data(from: url)
        
        return try JSONDecoder().decode([SecretAction].self, from: data)
    }
    
    @MainActor
    func submitAction(targetNumber: String, type: String) async throws -> String {
        let normalizedTargetNumber = targetNumber.normalizedEventNumber
        let url = baseURL.appendingPathComponent("actions")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "target_number": normalizedTargetNumber,
            "action_type": type
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if http.statusCode != 200 {
            let msg = String(data: data, encoding: .utf8) ?? "Serverfehler"
            throw NSError(domain: "", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: msg])
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

    func createBillboardAccessURL() async throws -> URL {
        let url = baseURL.appendingPathComponent("admin/billboard-access")
        var request = try adminRequest(url: url)
        request.httpMethod = "POST"

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

    func loadAdminDashboard() async throws {
        let url = baseURL.appendingPathComponent("admin/dashboard")
        let (data, response) = try await URLSession.shared.data(for: adminRequest(url: url))
        try validateAdminResponse(response)
        adminDashboard = try JSONDecoder().decode(AdminDashboard.self, from: data)
    }

    func loadAdminParticipants() async throws {
        let url = baseURL.appendingPathComponent("admin/participants")
        let (data, response) = try await URLSession.shared.data(for: adminRequest(url: url))
        try validateAdminResponse(response)
        adminParticipants = try JSONDecoder().decode(AdminParticipants.self, from: data)
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
        try await loadAdminDashboard()
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
        try await loadAdminDashboard()
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
        try await refreshAdminControlData()
        return result
    }

    func refreshAdminControlData() async throws {
        try await loadAdminDashboard()
        try await loadAdminParticipants()
    }

    func logout() {
        if let adminToken {
            var request = URLRequest(url: baseURL.appendingPathComponent("admin/logout"))
            request.httpMethod = "POST"
            request.setValue("Bearer \(adminToken)", forHTTPHeaderField: "Authorization")
            Task {
                _ = try? await URLSession.shared.data(for: request)
            }
        }

        adminToken = nil
        AdminSessionStore.clearToken()
        hasSavedAdminSession = false
        self.isLoggedIn = false
        self.number = ""
        self.matches = []
        self.actions = []
        self.isAdmin = false
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
        try await refreshAdminControlData()
    }

    private func validateAdminResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
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

private struct AdminLoginResponse: Decodable {
    let token: String
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
