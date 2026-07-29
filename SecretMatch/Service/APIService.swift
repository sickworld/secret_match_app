import Foundation
import Combine
import SwiftUI

@MainActor
class APIService: ObservableObject {
    static let shared = APIService()
    private init() {}

    @Published var isLoggedIn: Bool = false
    @Published var number: String = ""
    @Published var matches: [Match] = []
    @Published var actions: [SecretAction] = []
    @Published var isAdmin: Bool = false
    @Published var adminActions: [AdminAction] = []
    @Published var adminMatches: [AdminMatch] = []
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
    
    @MainActor
    func loadAdminActions() async {
        let url = baseURL.appendingPathComponent("admin/actions")

        do {
            let (data, response) = try await URLSession.shared.data(for: adminRequest(url: url))
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                handleExpiredAdminToken(response)
                print("❌ AdminActions HTTP Fehler")
                return
            }

            adminActions = try JSONDecoder().decode([AdminAction].self, from: data)
        } catch {
            print("❌ AdminActions Fehler:", error.localizedDescription)
            adminActions = []
        }
    }
    
    @MainActor
    func loadAdminMatches() async {
        let url = baseURL.appendingPathComponent("admin/matches")

        do {
            let (data, response) = try await URLSession.shared.data(for: adminRequest(url: url))
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                handleExpiredAdminToken(response)
                print("❌ AdminMatches HTTP Fehler")
                return
            }

            adminMatches = try JSONDecoder().decode([AdminMatch].self, from: data)
        } catch {
            print("❌ AdminMatches Fehler:", error.localizedDescription)
            adminMatches = []
        }
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
        let normalized = digits.drop(while: { $0 == "0" })
        return normalized.isEmpty && !digits.isEmpty ? "0" : String(normalized)
    }
}
