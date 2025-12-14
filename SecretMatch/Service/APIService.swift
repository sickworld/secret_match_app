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
    private let baseURL = URL(string: "https://secret-match.de/wp-json/secretmatch/v1")!

    func login(number: String) async throws {
        if isAdmin { return }
        let url = baseURL.appendingPathComponent("login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = "secretmatch_number=\(number)".data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        self.isLoggedIn = true
        self.number = number
    }

    func submitMatch(targetNumber: String, type: String) async throws -> String {
        let url = baseURL.appendingPathComponent("match")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let body = "target_number=\(targetNumber)&match_type=\(type)"
        request.httpBody = body.data(using: .utf8)
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
        let url = baseURL.appendingPathComponent("actions")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "target_number": targetNumber,
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
        request.httpBody = "password=\(password)".data(using: .utf8)

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let success = (response as? HTTPURLResponse)?.statusCode == 200

            if success {
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
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
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
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                print("❌ AdminMatches HTTP Fehler")
                return
            }

            adminMatches = try JSONDecoder().decode([AdminMatch].self, from: data)
        } catch {
            print("❌ AdminMatches Fehler:", error.localizedDescription)
            adminMatches = []
        }
    }

    func logout() {
        self.isLoggedIn = false
        self.number = ""
        self.matches = []
        self.actions = []
        self.isAdmin = false
    }
}
